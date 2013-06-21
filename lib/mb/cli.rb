module MotherBrain
  module Cli
    autoload :Base, 'mb/cli/base'
    autoload :Shell, 'mb/cli/shell'
    autoload :SubCommand, 'mb/cli/sub_command'

    # This is the main entry point for the CLI. It exposes the method {#execute!} to
    # start the CliGateway.
    #
    # @note the arity of {#initialize} and {#execute!} are extremely important for testing purposes. It
    #   is a requirement to perform in-process testing with Aruba. In process testing is much faster
    #   than spawning a new Ruby process for each test.
    class Runner
      # @param [Array] argv
      # @param [IO] stdin
      # @param [IO] stdout
      # @param [IO] stderr
      # @param [Kernel] kernel
      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
        @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
      end

      # Start the CLI Gateway
      def execute!
        MB::CliGateway.start(@argv)
      rescue MBError => ex
        ui.error ex
        @kernel.exit(ex.exit_code)
      rescue Ridley::Errors::ConnectionFailed => ex
        ui.error "[ERROR] Unable to connect to the configured Chef server: #{ex.message}."
        ui.error "[ERROR] Check your configuration and network settings and try again."
        @kernel.exit(MB::ChefConnectionError.exit_code)
      rescue Thor::Error => ex
        ui.error ex.message
        @kernel.exit(1)
      rescue Errno::EPIPE
        # This happens if a thor command is piped to something like `head`,
        # which closes the pipe when it's done reading. This will also
        # mean that if the pipe is closed, further unnecessary
        # computation will not occur.
        @kernel.exit(0)
      end

      # @return [MB::Cli::Shell::Color, MB::Cli::Shell::Basic]
      def ui
        @ui ||= MB::Cli::Shell.shell.new
      end
    end
  end
end
