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
    def initialize(command, proc)
      @command = command
      @proc = proc
      instance_eval(&proc)
    end

    def run(&block)
      if block_given?
        command.parent.instance_eval(&block)
      else
        command.parent
      end
    end
  end
end
