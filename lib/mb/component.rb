module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component < ContextualModel
    attr_reader :name
    attr_reader :groups
    attr_reader :commands

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

    def gears(klass)
      @gears[klass.keyword] ||= Set.new
    end

    # @param [#to_sym] name
    def group(name)
      self.groups.find { |group| group.name == name }
    end

    # @param [#to_sym] name
    # @raise [GroupNotFound] if the group is not found
    def group!(group_name)
      group = group(group_name)
      
      if group.nil?
        raise GroupNotFound, "Group #{group_name} does not exist on #{name}!"
      end

      group
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

    Gear.all.each do |klass|
      element_name    = Gear.element_name(klass)
      add_fun         = Gear.add_fun(klass)
      get_fun         = Gear.get_fun(klass)

      define_method add_fun do |object|
        unless send(get_fun, object.name).nil?
          raise DuplicateGear, "#{element_name.capitalize} '#{object.name}' already defined"
        end

        gears(klass).add(object)
      end

      define_method get_fun do |name|
        gears(klass).find { |obj| obj.name == name }
      end
    end

    private

      def dsl_eval(&block)
        self.attributes = CleanRoom.new(context, self, &block).attributes
        self
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < ContextualModel
      # @param [MB::Context] context
      # @param [MB::Component] component
      def initialize(context, component, &block)
        super(context)
        @component = component

        instance_eval(&block)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String, required: true)
      end

      def group(name, &block)
        component.add_group Group.new(name, context, &block)
      end

      def command(name, &block)
        component.add_command Command.new(name, context, component, &block)
      end

      Gear.all.each do |klass|
        define_method Gear.element_name(klass) do |*args, &block|
          component.send Gear.add_fun(klass), klass.new(context, component, *args, &block)
        end
      end

      private

        attr_reader :component
    end
  end
end
