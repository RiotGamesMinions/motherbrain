module MotherBrain 
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      attr_reader :plugin_loader

      # @param [Hash] config
      #
      # @return [MB::Config]
      def setup(config)
        mb_config = if config[:config].nil?
          begin
            MB::Config.from_file(File.expand_path(MB::Config.default_path))
          rescue
            MB::Config.new
          end
        else
          MB::Config.from_file(config[:config])
        end

        @plugin_loader = PluginLoader.new(mb_config.plugin_paths)
        self.plugin_loader.load_all

        self.plugin_loader.plugins.each do |plugin|
          self.register_plugin MB::PluginInvoker.fabricate(plugin)
        end

        mb_config
      end

      # @param [Class] klass
      def register_plugin(klass)
        self.register klass, klass.plugin.name, "#{klass.plugin.name} [COMMAND]", klass.plugin.description
      end

      protected

        def dispatch(meth, given_args, given_opts, config)
          args, opts = parse_args(given_args)
          setup(opts)
          super
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

    attr_reader :config

    def initialize(args = [], options = {}, config = {})
      super
      @config = self.class.setup(self.options)
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"

    no_tasks do
      def chef_conn
        @chef_conn ||= Ridley.connection(config.to_ridley)
      end
    end
  end
end
