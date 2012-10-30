module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Plugin < RealObjectBase
    class << self
      # Create a new plugin instance from the given context and content
      #
      # @param [MotherBrain::Context] context
      #
      # @raise [PluginLoadError]
      #
      # @yieldreturn [MotherBrain::Plugin]
      def load(context, &block)
        new(context, &block).validate!
      rescue => e
        raise PluginLoadError, e
      end

      # Load a plugin from the given file
      #
      # @param [MotherBrain::Context] context
      # @param [String] path
      #
      # @raise [PluginLoadError]
      #
      # @return [MotherBrain::Plugin]
      def from_file(context, path)
        block = proc {
          eval(File.read(path))
        }
        load(context, &block)
      end

      def key_for(name, version)
        "#{name}-#{version}".to_sym
      end
    end

    attr_reader :components
    attr_reader :commands
    attr_reader :dependencies

    attribute :name,
      type: String,
      required: true

    attribute :version,
      type: Solve::Version,
      required: true,
      coerce: lambda { |m|
        Solve::Version.new(m)
      }

    attribute :description,
      type: String,
      required: true

    attribute :author,
      type: [String, Array]

    attribute :email,
      type: [String, Array]

    # @param [MB::Context] context
    def initialize(context, &block)
      super(context)
      @components   = Set.new
      @commands     = Set.new
      @dependencies = HashWithIndifferentAccess.new

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [Symbol]
    def id
      self.class.key_for(self.name, self.version)
    end

    # @param [String] name
    #
    # @return [MB::Component]
    def component(name)
      component = components.find { |component| component.name == name }
      
      if component.nil?
        raise ComponentNotFound, "Component '#{name}' not found on plugin '#{self.name}' (#{self.version})"
      end

      component
    end

    # @param [String] name
    #
    # @return [MB::Command]
    def command(name)
      command = commands.find { |command| command.name == name }

      if command.nil?
        raise CommandNotFound, "Command '#{name}' not found on component '#{self.name}'"
      end

      command
    end

    # Finds the nodes for the given environment for each {Component} of the plugin groups them
    # by Component#name and Group#name into a Hash where the keys are Component#name and 
    # values are a hash where the keys are Group#name and the values are a Hash representing
    # a node from Chef.
    #
    # @example
    #
    #   {
    #     "activemq" => {
    #       database_masters" => [
    #         {
    #           "name" => "db-master1",
    #           ...
    #         }
    #       ],
    #       "database_slaves" => [
    #         {
    #           "name" => "db-slave1",
    #           ...
    #         },
    #         {
    #           "name" => "db-slave2",
    #           ...
    #         }
    #       ]
    #     }
    #   }
    #
    # @return [Hash]
    def nodes
      {}.tap do |nodes|
        self.components.each do |component|
          nodes[component.name] = component.nodes
        end
      end
    end

    # @param [MB::Component] component
    def add_component(component)
      self.components.add(component)
    end

    # @param [MB::Command] command
    def add_command(command)
      self.commands.add(command)
    end

    # @param [#to_s] name
    # @param [Solve::Constraint] constraint
    def add_dependency(name, constraint)
      self.dependencies[name.to_s] = Solve::Constraint.new(constraint)
    end

    # Completely validate a loaded plugin and raise an exception of errors
    #
    # @return [self]
    def validate!
      errors = self.validate

      unless errors.empty?
        raise errors
      end

      self
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(context, self, &block)
      end

    # A clean room bind the Plugin DSL syntax to. This clean room can later to
    # populate an instance of Plugin.
    #
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      bind_attribute :name
      bind_attribute :version
      bind_attribute :description
      bind_attribute :author
      bind_attribute :email

      # @param [#to_s] name
      # @param [#to_s] constraint
      def depends(name, constraint)
        binding.add_dependency(name, constraint)
      end

      # @param [#to_s] name
      def command(name, &block)
        binding.add_command Command.new(name, context, binding, &block)
      end

      # @param [#to_s] name
      def component(name, &block)
        binding.add_component Component.new(name, context, &block)
      end
    end
  end
end
