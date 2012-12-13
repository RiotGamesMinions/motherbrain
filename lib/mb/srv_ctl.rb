require 'optparse'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class SrvCtl
    class << self
      def parse(args)
        options = {
          config: MB::Config.default_path,
          daemon: false,
          pid: File.expand_path("~/fuck.pid")
        }

        OptionParser.new("Usage: mbsrv [options]") do |opts|          
          opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:log_level] = Logger::INFO
          end

          opts.on("-d", "--daemonize", "Run in daemon mode") do |v|
            options[:daemonize] = true
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
      if options[:daemonize]
        daemonize
      end
      
      MB::Application.run(config)
    end

    private

      attr_reader :config

      def daemonize
        Process.daemon
        File.open(options[:pid], 'w+') { f.write Process.pid }
      end
  end
end
