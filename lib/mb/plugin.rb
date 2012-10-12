module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Plugin
    class << self
      # Create a new plugin instance from the given context and content
      #
      # @param [MotherBrain::Context] context
      #
      # @raise [PluginLoadError]
      #
      # @yieldreturn [MotherBrain::Plugin]
      def load(context, &block)
        config      = context.config
        chef_conn   = context.chef_conn
        environment = context.environment

        lambda do |config, chef_conn, environment, &block|
          self.new(chef_conn, environment, &block)
        end.call(config, chef_conn, environment, &block)
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

    include Mixin::SimpleAttributes

    attr_reader :components
    attr_reader :commands
    attr_reader :dependencies

    def initialize(environment, chef_conn, &block)
      @environment  = environment
      @chef_conn    = chef_conn
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
    def nodes(environment)
      {}.tap do |nodes|
        self.components.each do |component|
          nodes[component.name] = component.nodes(environment)
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

    private

      attr_reader :environment
      attr_reader :chef_conn

      def dsl_eval(&block)
        self.attributes = CleanRoom.new(self, environment, chef_conn, &block).attributes
        self
      end

    # A clean room bind the Plugin DSL syntax to. This clean room can later to
    # populate an instance of Plugin.
    #
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom
      include Mixin::SimpleAttributes

      def initialize(plugin, environment, chef_conn, &block)
        @plugin = plugin
        @environment = environment
        @chef_conn = chef_conn
        instance_eval(&block)
      end

      # @param [String] value
      def name(value)
        set(:name, value, kind_of: String, required: true)
      end

      # @param [String] value
      def version(value)
        begin
          value = Solve::Version.new(value)
        rescue Solve::Errors::SolveError => e
          raise ValidationFailed, e.message
        end
        set(:version, value, kind_of: Solve::Version, required: true)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String)
      end

      # @param [String, Array<String>] value
      def author(value)
        set(:author, value, kind_of: [String, Array])
      end

      # @param [String, Array<String>] value
      def email(value)
        set(:email, value, kind_of: [String, Array])
      end

      def depends(name, constraint)
        plugin.add_dependency(name, constraint)
      end

      def command(&block)
        plugin.add_command Command.new(plugin, &block)
      end

      def component(&block)
        plugin.add_component Component.new(environment, chef_conn, &block)
      end

      private

        attr_reader :plugin
        attr_reader :environment
        attr_reader :chef_conn
    end
  end
end
