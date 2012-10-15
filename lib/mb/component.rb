module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component < ContextualModel
    attr_reader :groups
    attr_reader :commands

    def initialize(context, &block)
      super(context)
      @groups   = Set.new
      @commands = Set.new

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
      collection_name = Gear.collection_name(klass)
      collection_fun  = Gear.collection_fun(klass)
      add_fun         = Gear.add_fun(klass)
      get_fun         = Gear.get_fun(klass)

      define_method collection_fun do
        if instance_variable_defined?("@#{collection_name}")
          instance_variable_get("@#{collection_name}")
        else
          instance_variable_set("@#{collection_name}", Set.new)
        end
      end
      collection_fun

      define_method add_fun do |object|
        unless send(get_fun, object.name).nil?
          raise DuplicateGear, "#{element_name.capitalize} '#{object.name}' already defined"
        end

        send(collection_fun).add(object)
      end

      define_method get_fun do |name|
        send(collection_fun).find { |obj| obj.name == name }
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
      def initialize(context, component, &block)
        super(context)
        @component = component

        instance_eval(&block)
      end

      # @param [String] value
      def name(value)
        set(:name, value, kind_of: String, required: true)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String, required: true)
      end

      def group(&block)
        component.add_group Group.new(context, &block)
      end

      def command(&block)
        component.add_command Command.new(context, component, &block)
      end

      Gear.all.each do |klass|
        define_method Gear.element_name(klass) do |&block|
          component.send Gear.add_fun(klass), klass.new(context, component, &block)
        end
      end

      private

        attr_reader :component
    end
  end
end
