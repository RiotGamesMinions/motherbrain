module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    include Chozo::VariaModel

    attribute :name,
      type: String,
      required: true

    attribute :description,
      type: String,
      required: true

    attribute :version_attribute,
      type: String

    attr_reader :groups
    attr_reader :commands

    # @param [#to_s] name
    def initialize(name, &block)
      set_attribute(:name, name.to_s)
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
    # @param [#to_s] environment
    #
    # @raise [MB::EnvironmentNotFound] if the target environment does not exist
    # @raise [MB::ChefConnectionError] if there was an error communicating to the Chef Server
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
      unless Application.ridley.environment.find(environment)
        raise EnvironmentNotFound, "Environment: '#{environment}' not found on '#{Application.ridley.server_url}'"
      end

      {}.tap do |nodes|
        self.groups.each do |group|
          nodes[group.name] = group.nodes(environment)
        end
      end
    rescue Faraday::Error::ClientError, Ridley::Errors::RidleyError => e
      raise ChefConnectionError, "Could not connect to Chef server '#{Application.ridley.server_url}': #{e}"
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
      if klass.respond_to? :find
        klass.find(gears(klass), *args)
      else
        klass.new(*args)
      end
    end

    Gear.all.each do |klass|
      define_method Gear.get_fun(klass) do |*args|
        get_gear(klass, *args)
      end
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(self).instance_eval(&block)
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      dsl_attr_writer :description
      dsl_attr_writer :version_attribute

      def versioned(attribute_name = nil)
        version_attribute attribute_name || "#{@real_model.name}.version"
      end
      alias_method :versioned_with, :versioned

      def group(name, &block)
        real_model.add_group Group.new(name, &block)
      end

      def command(name, &block)
        real_model.add_command Command.new(name, real_model, &block)
      end

      Gear.all.each do |klass|
        define_method Gear.element_name(klass) do |*args, &block|
          real_model.add_gear(klass.new(real_model, *args, &block))
        end
      end
    end
  end
end
