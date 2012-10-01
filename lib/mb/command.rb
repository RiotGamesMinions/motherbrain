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
  end

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
