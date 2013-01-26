module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Invoker < InvokerBase
    class << self
      # @see {#Thor}
      def start(given_args = ARGV, config = {})
        args, opts = parse_args(given_args)
        if args.any? and (args & InvokerBase::NOCONFIG_TASKS).empty?
          app_config = configure(opts.dup)
          app_config.validate!
          MB::Application.run!(app_config)

          setup
        end

        super
      end

      def setup
        Application.plugin_manager.plugins.each do |plugin|
          self.register_plugin MB::PluginInvoker.fabricate(plugin)
        end
      end

      # @param [MotherBrain::PluginInvoker] klass
      def register_plugin(klass)
        self.register klass, klass.plugin.name, "#{klass.plugin.name} [COMMAND]", klass.plugin.description
      end

      private

        # Parse the given arguments into an instance of Thor::Argument and Thor::Options
        #
        # @param [Array] given_args
        #
        # @return [Array]
        def parse_args(given_args)
          args, opts = Thor::Options.split(given_args)
          thor_opts = Thor::Options.new(InvokerBase.class_options)
          parsed_opts = thor_opts.parse(opts)

          [ args, parsed_opts ]
        end
    end

    # @see {InvokerBase}
    def initialize(args = [], options = {}, config = {})
      super
      unless InvokerBase::NOCONFIG_TASKS.include?(config[:current_task].try(:name))
        self.class.setup
      end
    end

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

    desc "plugins", "Display all installed plugins and versions"
    def plugins
      if Application.plugin_manager.plugins.empty?
        MB.ui.say "No plugins found in your Berkshelf: '#{Application.plugin_manager.berkshelf_path}'"
        exit(0)
      end

      Application.plugin_manager.plugins.group_by(&:name).each do |name, plugins|
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
