module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Command
    include RealObject

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Run the proc stored in execute with the given arguments
    def invoke(*args)
      CommandRunner.new(self.parent, execute, *args)
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class CommandProxy
    include ProxyObject

    # @param [String] value
    def description(value)
      set(:description, value, kind_of: String, required: true)
    end

    def execute(&block)
      value = Proc.new(&block)
      set(:execute, value, kind_of: Proc, required: true)
    end
  end
end
