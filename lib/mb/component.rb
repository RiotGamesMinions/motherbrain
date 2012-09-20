module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    attr_reader :name

    def initialize(name, connection, environment)
      @name = name
      @connection = connection
      @environment = environment
      @groups = Hash.new
    end

    def group(name, &block)
      unless block_given?
        raise ArgumentError, "You must supply a block"
      end

      if has_group?(name)
        raise DuplicateGroup, "Group '#{name}'' already defined"
      end      

      add_group Group.new(name, &block)
    end

    def groups
      @groups.values
    end

    private

      attr_reader :connection
      attr_reader :environment

      def add_group(group)
        @groups[group.name.to_sym] = group
      end

      def has_group?(name)
        @groups.has_key?(name)
      end
  end
end
