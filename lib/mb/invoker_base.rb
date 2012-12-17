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

        level = nil
        level = Logger::DEBUG if options[:verbose]
        MB::Logging.setup(level: level, location: options[:logfile])

        config.rest_gateway.enable = false
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
      unless NOCONFIG_TASKS.include? config[:current_task].try(:name)
        @config = self.class.configure(self.options)
      end
    end

    class_option :config,
      type: :string,
      desc: "Path to a MotherBrain JSON configuration file.",
      aliases: "-c",
      banner: "PATH"
    class_option :verbose,
      type: :boolean,
      desc: "Output all log messages.",
      default: false,
      aliases: "-v"
    class_option :logfile,
      type: :string,
      desc: "Set the log file location.",
      default: "STDOUT",
      aliases: "-L",
      banner: "PATH"
  end
end
