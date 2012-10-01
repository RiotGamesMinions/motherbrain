module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Command
    include Mixin::SimpleAttributes

    def initialize(&block)
      if block_given?
        @attributes = CommandProxy.new(&block).attributes
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Run the proc stored in execute with the given arguments
    def invoke(*args)
      execute.call(*args)
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class CommandProxy
    include DSLProxy

    # @param [String] value
    def name(value)
      set(:name, value, kind_of: String, required: true)
    end

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
