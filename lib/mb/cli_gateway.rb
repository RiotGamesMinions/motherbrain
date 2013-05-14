module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CliGateway < Cli::Base
    class << self
      def invoked_opts
        @invoked_opts ||= HashWithIndifferentAccess.new
      end

      # @param [Hash] options
      #
      # @return [MB::Config]
      def configure(options)
        file = options[:config] || File.expand_path(MB::Config.default_path)

        begin
          config = MB::Config.from_file file
        rescue Chozo::Errors::InvalidConfig => ex
          ui.error "Invalid configuration file #{file}"
          ui.error ""
          ui.error ex.to_s
          exit_with(InvalidConfig)
        rescue Chozo::Errors::ConfigNotFound => ex
          ui.error "#{ex.message}"
          ui.error "Create one with `mb configure`"
          exit_with(ConfigNotFound)
        end

        level = Logger::WARN
        level = Logger::INFO if options[:verbose]
        level = Logger::DEBUG if options[:debug]

        if (options[:verbose] || options[:debug]) && options[:logfile].nil?
          options[:logfile] = STDOUT
        end

        MB::Logging.setup(level: level, location: options[:logfile])

        config.rest_gateway.enable = false
        config.plugin_manager.eager_loading = false
        config.plugin_manager.async_loading = false
        config
      end

      # Return the best plugin version for the given options.
      #
      # If no options are given, the latest version of the plugin will be loaded from either your
      # Berkshelf or the remote Chef server. If no plugin is found then the CLI will exit with an error.
      #
      # Specifying an environment will cause this function to check with the target environment
      # to see what plugin version is best suited be be returned for controlling that environment.
      #
      # If the specified environment does not exist then the latest plugin on the Chef server will be
      # returned. If no plugin is found then the CLI will exit with an error.
      #
      # Specifying a plugin_version will cause this function to return only a the plugin matching that
      # name and version. If no plugin is found then the CLI will exit with an error.
      #
      # @option options [String] :environment
      # @option options [String] :plugin_version
      #
      # @return [MB::Plugin]
      def find_plugin(name, options = {})
        if options[:plugin_version]
          plugin = plugin_manager.find(name, options[:plugin_version], remote: true)

          unless plugin
            ui.error "The cookbook #{name} (version #{options[:plugin_version]}) did not contain a motherbrain" +
              " plugin or it was not found in your Berkshelf or on the remote."
            exit(1)
          end

          plugin
        elsif options[:environment]
          plugin = begin
            ui.info "Determining best version of the #{name} plugin to use with the #{options[:environment]}" +
              " environment. This may take a few seconds..."
            plugin_manager.for_environment(name, options[:environment], remote: true)
          rescue MotherBrain::EnvironmentNotFound => ex
            ui.warn "No environment named #{options[:environment]} was found. Finding the latest version of the" +
              " #{name} plugin instead. This may take a few seconds..."
            plugin_manager.latest(name, remote: true)
          end

          unless plugin
            ui.error "No versions of the #{name} cookbook contained a motherbrain plugin that matched the" +
              " requirements of the #{options[:environment]} environment."
            exit(1)
          end

          plugin
        else
          ui.info "Finding the latest version of the #{name} plugin. This may take a few seconds..."
          plugin = plugin_manager.latest(name, remote: true)

          unless plugin
            ui.error "No versions of the #{name} cookbook in your Berkshelf or on the remote contained a" +
              " motherbrain plugin."
            exit(1)
          end

          plugin
        end
      end

      # @see {#Thor}
      def start(given_args = ARGV, config = {})
        config[:shell] ||= MB::Cli::Base.shell.new
        args, opts = parse_args(given_args)
        invoked_opts.merge!(opts)

        if requires_environment?(args)
          unless opts[:environment]
            MB.ui.say "No value provided for required option '--environment'"
            exit 1
          end
        end

        if start_mb_application?(args)
          app_config = configure(opts.dup)
          app_config.validate!

          MB::Application.run!(app_config)
          MB::Logging.add_argument_header

          # If the first argument is the name of a plugin, register that plugin and use it.
          if plugin_task?(args[0])
            name = args[0]

            plugin = find_plugin(name, opts)
            register_plugin(plugin)

            MB.ui.say "using #{plugin}"
            MB.ui.say ""
          end
        end

        dispatch(nil, given_args.dup, nil, config)
      rescue MBError => ex
        ui.error ex
        exit_with(ex)
      rescue Ridley::Errors::ConnectionFailed => ex
        ui.error "[ERROR] Unable to connect to the configured Chef server: #{ex.message}."
        ui.error "[ERROR] Check your configuration and network settings and try again."
        exit_with MB::ChefConnectionError.new
      rescue Errno::EPIPE
        # This happens if a thor command is piped to something like `head`,
        # which closes the pipe when it's done reading. This will also
        # mean that if the pipe is closed, further unnecessary
        # computation will not occur.
        exit(0)
      ensure
        Celluloid.shutdown
      end

      # Does the given argument array require a named argument for environment?
      #
      # @param [Array<String>] args the CLI arguments
      #
      # @return [Boolean]
      def requires_environment?(args)
        return false if args.count.zero?

        if args.include?("help")
          return false
        end

        if SKIP_ENVIRONMENT_TASKS.include?(args.first)
          return false
        end

        if args.count == 1
          return false
        end

        # All commands/subcommands require an environment unless specified in
        # the {SKIP_ENVIRONMENT_TASKS} constant array.
        true
      end

      # Did the user call a plugin task?
      #
      # @param [String] name
      #
      # @return [Boolean]
      def plugin_task?(name)
        non_plugin_tasks = tasks.keys.map(&:to_s)
        !non_plugin_tasks.find { |task| task == name }.present?
      end

      # Create and register a sub command for the given plugin
      #
      # @param [MB::Plugin] plugin
      #
      # @return [MB::Cli::SubCommand]
      #   the sub command generated and registered
      def register_plugin(plugin)
        sub_command = MB::Cli::SubCommand.new(plugin)
        register_subcommand(sub_command)
        sub_command
      end

      # Check if we should start the motherbrain application stack based on the
      # arguments passed to the CliGateway. The application stack won't be started
      # if the first argument is a member of {SKIP_CONFIG_TASKS}.
      #
      # @param [Array] args
      #
      # @return [Boolean]
      def start_mb_application?(args)
        args.any? && !SKIP_CONFIG_TASKS.include?(args.first)
      end

      private

        # Parse the given arguments into an instance of Thor::Argument and Thor::Options
        #
        # @param [Array] given_args
        #
        # @return [Array]
        def parse_args(given_args)
          args, opts = Thor::Options.split(given_args)
          thor_opts = Thor::Options.new(self.class_options)
          parsed_opts = thor_opts.parse(opts)

          [ args, parsed_opts ]
        end
    end

    SKIP_CONFIG_TASKS = [
      "configure",
      "help",
      "init",
      "version"
    ].freeze

    SKIP_ENVIRONMENT_TASKS = [
      "environment"
    ].freeze

    CREATE_ENVIRONMENT_TASKS = [
      "bootstrap",
      "provision"
    ].freeze

    source_root File.join(__FILE__, '../../../templates')

    def initialize(args = [], options = {}, config = {})
      super
      opts = self.options.dup

      validate_environment

      unless SKIP_CONFIG_TASKS.include?(config[:current_command].try(:name))
        self.class.configure(opts)
      end
    end

    map 'ver' => :version

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"
    class_option :verbose,
      type: :boolean,
      desc: "Increase verbosity of output.",
      default: false,
      aliases: "-v"
    class_option :debug,
      type: :boolean,
      desc: "Output all log messages.",
      default: false,
      aliases: "-d"
    class_option :logfile,
      type: :string,
      desc: "Set the log file location.",
      aliases: "-L",
      banner: "PATH"
    class_option :plugin_version,
      type: :string,
      desc: "Plugin version to use",
      default: nil,
      aliases: "-p"
    class_option :environment,
      type: :string,
      default: nil,
      required: false,
      desc: "Chef environment",
      aliases: "-e"

    method_option :force,
      type: :boolean,
      default: false,
      desc: "create a new configuration file even if one already exists.",
      aliases: "-f"
    desc "configure", "create a new configuration file based on a set of interactive questions"
    def configure(path = MB::Config.default_path)
      path = File.expand_path(path)

      if File.exist?(path) && !options[:force]
        raise MB::ConfigExists, "A configuration file already exists. Re-run with the --force flag if you wish to overwrite it."
      end

      config = MB::Config.new(path)

      config.chef.api_url     = MB.ui.ask "Enter a Chef API URL:", default: config.chef.api_url
      config.chef.api_client  = MB.ui.ask "Enter a Chef API Client:", default: config.chef.api_client
      config.chef.api_key     = MB.ui.ask "Enter the path to the client's Chef API Key:", default: config.chef.api_key
      config.ssh.user         = MB.ui.ask "Enter a SSH user:", default: config.ssh.user
      config.ssh.password     = MB.ui.ask "Enter a SSH password:", default: config.ssh.password
      config.save

      MB.ui.say "Config written to: '#{path}'"
    end

    desc "init [PATH]", "Create a MotherBrain plugin for the current cookbook"
    def init(path = Dir.pwd)
      metadata = File.join(path, 'metadata.rb')

      unless File.exist?(metadata)
        MB.ui.say "#{path} is not a cookbook"
        return
      end

      cookbook = CookbookMetadata.from_file(metadata)
      config = { name: cookbook.name, groups: %w[default] }
      template 'bootstrap.json', File.join(path, 'bootstrap.json'), config
      template 'motherbrain.rb', File.join(path, 'motherbrain.rb'), config

      MB.ui.say [
        "",
        "motherbrain plugin created.",
        "",
        "Take a look at motherbrain.rb and bootstrap.json,",
        "and then bootstrap with:",
        "",
        "  mb #{cookbook.name} bootstrap bootstrap.json",
        "",
        "To see all available commands, run:",
        "",
        "  mb #{cookbook.name} help",
        "\n"
      ].join("\n")
    end

    method_option :remote,
      type: :boolean,
      default: false,
      desc: "search the remote Chef server and include plugins from the results"
    desc "plugins", "Display all installed plugins and versions"
    def plugins
      if options[:remote]
        MB.ui.say "\n"
        MB.ui.say "** listing local and remote plugins..."
        MB.ui.say "\n"
      else
        MB.ui.say "\n"
        MB.ui.say "** listing local plugins...\n"
        MB.ui.say "\n"
      end

      plugins = plugin_manager.list(remote: options[:remote])

      if plugins.empty?
        errmsg = "No plugins found in your Berkshelf: '#{Application.plugin_manager.berkshelf_path}'"

        if options[:remote]
          errmsg << " or on remote: '#{Application.config.chef.api_url}'"
        end

        MB.ui.say errmsg
        exit(0)
      end

      plugins.group_by(&:name).each do |name, plugins|
        versions = plugins.collect(&:version).reverse!
        MB.ui.say "#{name}: #{versions.join(', ')}"
      end
    end

    desc "version", "Display version and license information"
    def version
      MB.ui.say version_header
      MB.ui.say "\n"
      MB.ui.say license
    end

    private

      def validate_environment
        return if testing?

        environment_name = options[:environment]

        return unless environment_name

        environment_manager.find(environment_name)
      rescue EnvironmentNotFound
        raise unless CREATE_ENVIRONMENT_TASKS.include?(args.first)

        prompt_to_create_environment environment_name
      end

      def prompt_to_create_environment(environment_name)
        message = "Environment '#{environment_name}' does not exist, would you like to create it?"
        case ask(message, limited_to: %w[y n q], default: 'y')
        when 'y' then environment_manager.create(environment_name)
        when 'n' then ui.warn "Not creating environment"
        when 'q' then abort
        end
      end

      def testing?
        MB.testing?
      end

      def version_header
        "MotherBrain (#{MB::VERSION})"
      end

      def license
        File.read(MB.app_root.join('LICENSE'))
      end
  end
end

require 'mb/cli_gateway/sub_commands'
