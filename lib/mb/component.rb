module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Component
    include Mixin::SimpleAttributes

    def initialize(&block)
      if block_given?
        @attributes = ComponentProxy.new(&block).attributes
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    def group(name)
      self.attributes[:groups][name.to_sym]
    end

    def groups
      self.attributes[:groups].values
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class ComponentProxy
    include DSLProxy
    include Plugin::Commands

    # @param [String] value
    def name(value)
      set(:name, value, kind_of: String, required: true)
    end

    # @param [#to_s] name
    def group(name, &block)
      group = get_group(name)

      unless group.nil?
        raise DuplicateGroup, "Group '#{name}'' already defined"
      end

      add_group Group.new(name, &block)
    end

    def attributes
      super.merge!(commands: self.commands)
    end

    private

      # @param [MB::Group] group
      def add_group(group)
        self.attributes[:groups] ||= Hash.new

        self.attributes[:groups][group.id] = group
      end

      # @param [#to_sym] name
      #
      # @return [MB::Group]
      def get_group(name)
        self.attributes[:groups] ||= Hash.new

        self.attributes[:groups].fetch(name.to_sym, nil)
      end
    end
end
