require 'optparse'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class SrvCtl
    class << self
      def parse(args)
        options = {
          config: MB::Config.default_path
        }

        OptionParser.new("Usage: mbsrv [options]") do |opts|          
          opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:log_level] = Logger::INFO
          end

          opts.on("-d", "--[no-]debug", "Run debug") do |v|
            options[:log_level] = Logger::DEBUG
          end

          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end.parse!(args)

        options
      end

      def run(args)
        MB::Logging.setup(level: Logger::INFO)
        new(parse(args)).start
      end
    end

    attr_reader :options

    def initialize(options = {})
      @options = options
      @config  = MB::Config.from_file(@options[:config])

      @config.rest_gateway.enable = true
      MB::Logging.setup(level: @options[:log_level])
    end

    def start
      MB::Application.run(config)
    end

    private

      attr_reader :config
  end
end
