module MotherBrain
  class CommandInvoker
    class Worker
      include Celluloid

      # @return [MB::Command]
      attr_reader :command
      # @return [String]
      attr_reader :environment
      # @return [Array]
      attr_reader :node_filter

      # @param [MB::Command] command
      #   command to invoke
      # @param [String] environment
      #   environment to invoke this command on
      # @param [Array] node_filter = nil
      #	  list of nodes to limit the command to
      def initialize(command, environment, node_filter = nil)
        @command     = command
        @environment = environment
        @node_filter = node_filter
      end

      # @param [MB::Job] job
      # @param [Array] arguments
      def run(job, arguments = Array.new)
        arguments ||= Array.new

        msg = "Invoking #{command.type} command #{command.scope.name} #{command.name} on #{environment}"
        msg << " with arguments: #{arguments}" if arguments.any?
        job.set_status(msg)

        command.invoke(job, environment, node_filter, *arguments)
      rescue RemoteCommandError => ex
        abort(ex)
      end
    end
  end
end
