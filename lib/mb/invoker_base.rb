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
        MB::Logging.setup(level: level, location: options[:logfile])

        config.rest_gateway.enable = false
        config
      end

      def spinner
        Enumerator.new do |e|
          loop do
            e.yield '|'
            e.yield '/'
            e.yield '-'
            e.yield '\\'
          end
        end
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
      default: "STDOUT",
      aliases: "-L",
      banner: "PATH"

    private

      def spinner
        @spinner ||= self.class.spinner
      end

      def spinner(message = nil)
        printf("\r#{message}%s", spinner.next)
        sleep(0.1)
      end
  end
end
