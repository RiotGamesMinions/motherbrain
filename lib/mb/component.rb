module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    attr_reader :name

    def initialize(name, &block)
      @name = name
      @groups = Hash.new

      instance_eval(&block) if block_given?
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    def groups
      @groups.values
    end

    # @param [#to_s] name
    def group(name, &block)
      group = get_group(name)

      unless block_given?
        return group
      end

      unless group.nil?
        raise DuplicateGroup, "Group '#{name}'' already defined"
      end      

      add_group Group.new(name, &block)
    end

    private

      # @param [MB::Group] group
      def add_group(group)
        @groups[group.id] = group
      end

      # @param [#to_sym] name
      #
      # @return [MB::Group]
      def get_group(name)
        @groups.fetch(name.to_sym, nil)
      end
  end
end
