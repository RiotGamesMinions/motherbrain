module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class InvokerBase < Thor
    class << self
      # @param [Hash] options
      #
      # @return [MB::Config]
      def configure(options)
        file = options[:config] || File.expand_path(MB::Config.default_path)

        begin
          config = MB::Config.from_file file
        rescue Chozo::Errors::ConfigNotFound => e
          raise e.class.new "#{e.message}\nCreate one with `mb configure`"
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
        config
      end
    end

    include MB::Locks

    NOCONFIG_TASKS = [
      "configure",
      "help",
      "version"
    ].freeze

    attr_reader :config

    def initialize(args = [], options = {}, config = {})
      super
      opts = self.is_a?(Invoker) ? self.options.dup : self.options.merge(Invoker.invoked_opts)
      unless NOCONFIG_TASKS.include? config[:current_task].try(:name)
        @config = self.class.configure(opts)
      end
    end
  end
end
