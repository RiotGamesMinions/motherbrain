module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component < RealModelBase
    attr_reader :name
    attr_reader :groups
    attr_reader :commands

    attribute :description,
      type: String,
      required: true

    # @param [#to_s] name
    # @param [MB::Context] context
    def initialize(name, context, &block)
      super(context)
      @name     = name.to_s
      @groups   = Set.new
      @commands = Set.new
      @gears    = Hash.new

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # @param [#to_sym] name
    def group(name)
      self.groups.find { |group| group.name == name }
    end

    # @param [#to_sym] group_name
    #
    # @raise [GroupNotFound] if the group is not found
    #
    # @return [MB::Group]
    def group!(group_name)
      group = group(group_name)
      
      if group.nil?
        raise GroupNotFound, "Group #{group_name} does not exist on #{name}!"
      end

      group
    end

    # @param [#to_s] name
    #
    # @return [Boolean]
    def has_group?(name)
      group(name.to_s).present?
    end

    # @param [#to_sym] name
    def command(name)
      self.commands.find { |command| command.name == name }
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
    def nodes
      {}.tap do |nodes|
        self.groups.each do |group|
          nodes[group.name] = group.nodes
        end
      end
    end

    def add_group(group)
      self.groups.add(group)
    end

    # @param [MB::Command] command
    def add_command(command)
      self.commands.add(command)
    end

    # Returns the gears of class klass defined on this component.
    #
    # @param [MB::Gear] klass the class of the gears to find
    #
    # @return [Array<MB::Gear>]
    def gears(klass)
      @gears[klass.keyword] ||= Set.new
    end

    # Adds a gear to this component.
    #
    # @param [MB::Gear] gear the gear
    def add_gear(gear)
      klass = gear.class

      unless get_gear(klass, gear.name).nil? 
        raise DuplicateGear, "#{klass.keyword.capitalize} '#{gear.name}' already defined"
      end

      gears(klass).add(gear)
    end

    # Finds a gear of class klass identified by *args.
    #
    # @param [MB::Gear] klass the class of the gear to search for
    # @param [Array] args the identifiers for the gear to find
    #
    # @example searching for a service gear
    #
    #   get_gear(MB::Gear::Service, "service_name")
    #
    # @example searching for a jmx gear
    #
    #   get_gear(MB::Gear::Jmx)
    #
    # @return [MB::Gear]
    def get_gear(klass, *args)
      klass.find(gears(klass), *args)
    end

    Gear.all.each do |klass|
      define_method Gear.get_fun(klass) do |*args|
        get_gear(klass, *args)
      end
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(context, self).instance_eval(&block)
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      dsl_attr_writer :description

      def group(name, &block)
        real_model.add_group Group.new(name, context, &block)
      end

      def command(name, &block)
        real_model.add_command Command.new(name, context, real_model, &block)
      end

      Gear.all.each do |klass|
        define_method Gear.element_name(klass) do |*args, &block|
          real_model.add_gear(klass.new(context, real_model, *args, &block))
        end
      end
    end
  end
end
