module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Invoker < InvokerBase
    class << self
      # @return [MotherBrain::PluginLoader]
      attr_reader :plugin_loader

      # @see {#Thor}
      def start(given_args = ARGV, config = {})
        args, opts = parse_args(given_args)
        if args.any? and (args & InvokerBase::NOCONFIG_TASKS).empty?
          setup(configure(opts))
        end
        
        super
      end

      # @param [MotherBrain:Context] context
      def setup(context)
        @plugin_loader = PluginLoader.new(context)
        self.plugin_loader.load_all

        self.plugin_loader.plugins.each do |plugin|
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
        self.class.setup(self.context)
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

      @config.chef_api_url     = MB.ui.ask "Enter a Chef API URL: "
      @config.chef_api_client  = MB.ui.ask "Enter a Chef API Client: "
      @config.chef_api_key     = MB.ui.ask "Enter the path to the client's Chef API Key: "
      @config.ssh_user         = MB.ui.ask "Enter a SSH user: "
      @config.ssh_password     = MB.ui.ask "Enter a SSH password: "
      @config.save

      MB.ui.say "Config written to: '#{path}'"
    end

    desc "plugins", "Display all installed plugins and versions"
    def plugins
      if self.class.plugin_loader.plugins.empty?
        paths = self.class.plugin_loader.paths.to_a.collect { |path| "'#{path}'" }

        MB.ui.say "No MotherBrain plugins found in any of your configured plugin paths!"
        MB.ui.say "\n"
        MB.ui.say "Paths: #{paths.join(', ')}"
        exit(0)
      end

      self.class.plugin_loader.plugins.group_by(&:name).each do |name, plugins|
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

      def version_header
        "MotherBrain (#{MB::VERSION})"
      end

      def license
        File.read(MB.root.join('LICENSE'))
      end
  end
end
