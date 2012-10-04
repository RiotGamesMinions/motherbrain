module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class CommandRunner
    # @return [MotherBrain::Command]
    attr_reader :command
    # @return [Proc]
    attr_reader :proc

    # @param [MotherBrain::Command] command
    # @param [Proc] proc
    def initialize(command, proc, *args)
      @command = command
      @proc = proc
      @arguments = args
      instance_eval(&proc)
    end

    def run(&block)
      if block_given?
        yield(self)
      else
        self
      end
    end

    private

      def method_missing(message, *args)
        command.parent.send(message, *args) || super
      end
  end
end
