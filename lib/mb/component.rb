module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    include RealObject
    include DynamicGears

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

    # Run a command of the given name on the component.
    #
    # @param [String, Symbol] name
    def invoke(name)
      self.command(name).invoke
    end

    # Finds the nodes for the given environment for each {Group} and groups them
    # by Group#name into a Hash where the keys are Group#name and values are a Hash
    # representation of a node from Chef.
    #
    # @example
    #
    #   {
    #     "database_masters" => [
    #       {
    #         "name" => "db-master1",
    #         ...
    #       }
    #     ],
    #     "database_slaves" => [
    #       {
    #         "name" => "db-slave1",
    #         ...
    #       },
    #       {
    #         "name" => "db-slave2"
    #         ...
    #       }
    #     ]
    #   }
    #
    # @return [Hash]
    def nodes(environment)
      {}.tap do |nodes|
        self.groups.each do |group|
          nodes[group.name] = group.nodes(environment)
        end
      end
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
