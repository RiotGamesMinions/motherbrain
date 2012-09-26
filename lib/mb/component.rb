module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    attr_reader :plugin
    attr_reader :name

    def initialize(plugin, name)
      @plugin = plugin
      @name = name
      @groups = Hash.new
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # @param [#to_s] name
    def group(name, &block)
      unless block_given?
        raise ArgumentError, "You must supply a block"
      end

      if has_group?(name)
        raise DuplicateGroup, "Group '#{name}'' already defined"
      end      

      add_group Group.new(name, &block)
    end

    # @return [Array<MB::Group>]
    def groups
      @groups.values
    end

    # @param [MB::Group]
    def add_group(group)
      @groups[group.name.to_sym] = group
    end

    # @param [#to_sym] name
    #
    # @return [Boolean]
    def has_group?(name)
      @groups.has_key?(name.to_sym)
    end
  end
end
