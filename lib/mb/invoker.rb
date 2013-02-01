module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Invoker < InvokerBase
    class << self
      def invoked_opts
        @invoked_opts ||= {}
      end

      # @see {#Thor}
      def start(given_args = ARGV, config = {})
        args, opts = parse_args(given_args)
        invoked_opts.merge!(opts)
        if args.any? and (args & InvokerBase::NOCONFIG_TASKS).empty?
          app_config = configure(opts.dup)
          app_config.validate!
          MB::Application.run!(app_config)
          register_plugin(args[0], opts[:plugin_version]) unless args[0] == "plugins"
        end

        super
      end

      # Load and register a plugin
      #
      # @param [String] name
      # @param [String] version
      def register_plugin(name, version = nil)
        if plugin = MB::Application.plugin_manager.find(name, version)
          klass = MB::PluginInvoker.fabricate(plugin)
          self.register klass, klass.plugin.name, "#{klass.plugin.name} [COMMAND]", klass.plugin.description
          MB.ui.say "#{plugin.name} (#{plugin.version})"
        else
          cookbook_identifier = "#{name}"
          cookbook_identifier += " (version #{version})" if version
          MB.ui.say "No cookbook with #{cookbook_identifier} plugin was found in your Berkshelf."
        end
      end

      private

        # Parse the given arguments into an instance of Thor::Argument and Thor::Options
        #
        # @param [Array] given_args
        #
        # @return [Array]
        def parse_args(given_args)
          args, opts = Thor::Options.split(given_args)
          thor_opts = Thor::Options.new(Invoker.class_options)
          parsed_opts = thor_opts.parse(opts)

          [ args, parsed_opts ]
        end
    end

    include MB::Mixin::Services

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

    method_option :force,
      type: :boolean,
      default: false,
      desc: "create a new configuration file even if one already exists."
    desc "configure", "create a new configuration file based on a set of interactive questions"
    def configure(path = MB::Config.default_path)
      path = File.expand_path(path)

      if File.exist?(path) && !options[:force]
        raise MB::ConfigExists, "A configuration file already exists. Re-run with the --force flag if you wish to overwrite it."
      end

      @config = MB::Config.new(path)

      @config.chef.api_url     = MB.ui.ask "Enter a Chef API URL: "
      @config.chef.api_client  = MB.ui.ask "Enter a Chef API Client: "
      @config.chef.api_key     = MB.ui.ask "Enter the path to the client's Chef API Key: "
      @config.ssh.user         = MB.ui.ask "Enter a SSH user: "
      @config.ssh.password     = MB.ui.ask "Enter a SSH password: "
      @config.save

      MB.ui.say "Config written to: '#{path}'"
    end

    method_option :force,
      type: :boolean,
      default: false,
      desc: "perform the configuration even if the environment is locked"
    desc "configure_environment ENVIRONMENT MANIFEST", "configure a Chef environment"
    def configure_environment(environment, attributes_file)
      attributes_file = File.expand_path(attributes_file)

      begin
        content = File.read(attributes_file)
      rescue Errno::ENOENT
        MB.ui.say "No attributes file found at: '#{attributes_file}'"
        exit(1)
      end

      begin
        attributes = MultiJson.decode(content)
      rescue MultiJson::DecodeError => ex
        MB.ui.say "Error decoding JSON from: '#{attributes_file}'"
        MB.ui.say ex
        exit(1)
      end

      job = environment_manager.configure(environment, attributes: attributes, force: options[:force])

      CliClient.new(job).display
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

      plugins = Application.plugin_manager.list(options[:remote])

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

    method_option :api_url,
      type: :string,
      desc: "URL to the Environment Factory API endpoint"
    method_option :api_key,
      type: :string,
      desc: "API authentication key for the Environment Factory"
    method_option :ssl_verify,
      type: :boolean,
      desc: "Should we verify SSL connections?",
      default: false
    desc "destroy ENVIRONMENT", "Destroy a provisioned environment"
    def destroy(environment)
      destroy_options = Hash.new.merge(options).deep_symbolize_keys

      job = Provisioner::Manager.instance.destroy(environment, destroy_options)

      CliClient.new(job).display
    end

    desc "version", "Display version and license information"
    def version
      MB.ui.say version_header
      MB.ui.say "\n"
      MB.ui.say license
    end

    private

      def version_header
        "MotherBrain (#{MB::VERSION})"
      end

      def license
        File.read(MB.app_root.join('LICENSE'))
      end
  end
end
