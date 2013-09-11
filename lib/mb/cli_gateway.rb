module MotherBrain
  class CliGateway < Cli::Base
    class << self
      def invoked_opts
        @invoked_opts ||= Hashie::Mash.new
      end

      # @param [Hash] options
      #
      # @return [MB::Config]
      def configure(options)
        file = options[:config] || File.expand_path(MB::Config.default_path)

        begin
          config = MB::Config.from_file(file)
        rescue MB::InvalidConfig => ex
          ui.error ex.to_s
          exit_with(InvalidConfig)
        rescue MB::ConfigNotFound => ex
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
        elsif local_plugin?
          ui.info "Loading #{name} plugin from: #{Dir.pwd}"
          plugin_manager.load_installed(Dir.pwd, allow_failure: false)
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

      # Determines if we're running inside of a cookbook with a plugin.
      #
      # @return [Boolean]
      def local_plugin?
        Dir.has_mb_plugin?(Dir.pwd)
      end

      # @see {#Thor}
      def start(given_args = ARGV, config = {})
        config[:shell] ||= MB::Cli::Shell.shell.new
        args, opts = parse_args(given_args)
        invoked_opts.merge!(opts)

        if requires_environment?(args)
          unless opts[:environment]
            ui.say "No value provided for required option '--environment'"
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

            ui.say "using #{plugin}"
            ui.say ""
          end
        end

        dispatch(nil, given_args.dup, nil, config)
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
      "version",
      "ver"
    ].freeze

    SKIP_ENVIRONMENT_TASKS = [
      "environment",
      "plugin",
      "template",
      "purge"
    ].freeze

    CREATE_ENVIRONMENT_TASKS = [
      "bootstrap",
      "provision"
    ].freeze

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
      desc: "Path to a motherbrain JSON configuration file.",
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

      config.chef.api_url     = ui.ask "Enter a Chef API URL:", default: config.chef.api_url
      config.chef.api_client  = ui.ask "Enter a Chef API Client:", default: config.chef.api_client
      config.chef.api_key     = ui.ask "Enter the path to the client's Chef API Key:", default: config.chef.api_key
      config.ssh.user         = ui.ask "Enter a SSH user:", default: config.ssh.user
      config.ssh.password     = ui.ask "Enter a SSH password:", default: config.ssh.password
      config.save

      ui.say "Config written to: '#{path}'"
    end

    desc "console", "Start an interactive motherbrain console"
    def console
      require 'mb/console'
      MB::Console.start
    end

    method_option :skip_chef,
      type: :boolean,
      desc: "Skip removing the Chef installation from the node",
      default: false
    desc "purge HOST", "Remove Chef from node and purge it's data from the Chef server"
    def purge(hostname)
      job = node_querier.async_purge(hostname, options.to_hash.symbolize_keys)
      CliClient.new(job).display
    end

    desc "version", "Display version and license information"
    def version
      ui.say version_header
      ui.say "\n"
      ui.say license
    end

    desc "template NAME PATH_OR_URL", "Download and install a bootstrap template"
    def template(name, path_or_url)
      MB::Bootstrap::Template.install(name, path_or_url)
      ui.say "Installed template `#{name}`"
    end

    private

      def validate_environment

        return if testing?

        environment_name = options[:environment]

        return unless environment_name

        environment_manager.find(environment_name)
      rescue EnvironmentNotFound
        raise unless CREATE_ENVIRONMENT_TASKS.include?(args.first)


        case options[:on_environment_missing]
        when 'prompt' then prompt_to_create_environment(environment_name)
        when 'create' then create_environment(environment_name)
        when 'quit' then abort
        end
      end

      def prompt_to_create_environment(environment_name)
        message = "Environment '#{environment_name}' does not exist, would you like to create it?"
        case ask(message, limited_to: %w[y n q], default: 'y')
        when 'y' then create_environment(environment_name)
        when 'n' then ui.warn "Not creating environment"
        when 'q' then abort
        end
      end

      def testing?
        MB.testing?
      end

      def version_header
        "motherbrain (#{MB::VERSION})"
      end

      def license
        File.read(MB.app_root.join('LICENSE'))
      end

      private 

        def create_environment(environment_name)
          environment_manager.create(environment_name)
        end
  end
end

require 'mb/cli_gateway/sub_commands'
