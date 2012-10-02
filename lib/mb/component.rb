module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    include Mixin::SimpleAttributes

    def initialize(&block)
      if block_given?
        @attributes = ComponentProxy.new(&block).attributes
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # @param [#to_sym] name
    def group(name)
      self.attributes[:groups][name.to_sym]
    end

    def groups
      self.attributes[:groups].values
    end

    # @param [#to_sym] name
    def command(name)
      self.attributes[:commands][name.to_sym]
    end

    def commands
      self.attributes[:commands].values
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class ComponentProxy
    include ProxyObject
    include PluginDSL::Commands
    include PluginDSL::Groups
    include PluginDSL::Gears

    # @param [String] value
    def description(value)
      set(:description, value, kind_of: String, required: true)
    end

    def attributes
      super.merge!(commands: self.commands, groups: self.groups)
    end
  end
end
