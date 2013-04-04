module MotherBrain
  class CommandInvoker
    # @author Jamie Winsor <reset@riotgames.com>
    class Worker
      include Celluloid

      # @return [MB::Command]
      attr_reader :command
      # @return [String]
      attr_reader :environment

      # @param [MB::Command] command
      #   command to invoke
      # @param [String] environment
      #   environment to invoke this command on
      def initialize(command, environment)
        @command     = command
        @environment = environment
      end

      # @param [MB::Job]
      # @param [Array] arguments
      def run(job, arguments = nil)
        arguments ||= Array.new

        msg = "invoking #{command.type} command #{command.scope.name} #{command.name} on #{environment}"
        msg << " with arguments: #{arguments}" if arguments.any?
        job.set_status(msg)

        command.invoke(environment, *arguments)
      end
    end
  end
end
