require 'optparse'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class SrvCtl
    class << self
      # @param [Array] args
      # @param [#to_s] filename
      #
      # @return [Hash]
      def parse(args, filename)
        options = {
          config: MB::Config.default_path,
          log_level: Logger::WARN,
          pid: nil
        }

        OptionParser.new("Usage: #{filename} [options]") do |opts|
          opts.on("-v", "--[no-]verbose", "run with verbose output") do
            options[:log_level] = Logger::INFO
          end

          opts.on("--debug", "run with debug output") do
            options[:log_level] = Logger::DEBUG
          end

          opts.on("-d", "--daemonize", "run in daemon mode") do
            options[:daemonize]    = true
            options[:log_location] = FileSystem.logs.join('mbsrv.log').to_s
          end

          opts.on("--pid [PATH]", String, "pid file to read/write from") do |opt|
            options[:pid] = File.expand_path(opt)
          end

          opts.on("-l", "--log [PATH}", String, "path to log file") do |opt|
            options[:log_location] = opt
          end

          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end.parse!(args)

        options
      end

      # @param [Array] args
      # @param [String] filename
      def run(args, filename)
        MB::Logging.setup(level: Logger::INFO)
        new(parse(args, filename)).start
      end
    end

    attr_reader :options

    def initialize(options = {})
      @options = options

      if @options[:log_location]
        setup_logdir
      end

      MB::Logging.setup(@options.slice(:level, :location))
      @config = MB::Config.from_file(@options[:config])

      unless @options[:daemonize].nil?
        @config.server.daemonize = @options[:daemonize]
      end

      if @options[:pid].nil?
        @options[:pid] = @config.server.pid
      end

      @config.rest_gateway.enable = true
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
        unless File.writable?(File.dirname(options[:pid]))
          puts "startup failed: couldn't write pid to #{options[:pid]}"
          exit 1
        end

        Process.daemon
        File.open(options[:pid], 'w+') { f.write Process.pid }
      end

      def setup_logdir
        FileUtils.mkdir_p(File.dirname(options[:log_location]))
      end
  end
end
