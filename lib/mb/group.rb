module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Group
    include Mixin::SimpleAttributes

    # @param [Symbol, String] name
    def initialize(&block)
      if block_given?
        @attributes = GroupProxy.new(&block).attributes
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # @param [#to_sym] name
    def chef_attribute(name)
      self.chef_attributes.fetch(name.to_sym, nil)
    end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class GroupProxy
    include ProxyObject

    # @param [String] value
    def name(value)
      set(:name, value, kind_of: String, required: true)
    end

    # @param [String] value
    def description(value)
      set(:description, value, kind_of: String)
    end

    def recipes
      @recipes ||= Set.new
    end

    # @param [#to_s] value
    #
    # @return [Set<String>]
    def recipe(value)
      self.recipes.add(value.to_s)
    end

    def roles
      @roles ||= Set.new
    end

    # @param [#to_s] value
    #
    # @return [Set<String>]
    def role(value)
      self.roles.add(value.to_s)
    end

    def chef_attributes
      @chef_attributes ||= Hash.new
    end

    # @param [#to_s] attr_key
    # @param [Object] attr_value
    def chef_attribute(attr_key, attr_value)
      attr_key = attr_key.to_s

      if self.chef_attributes.has_key?(attr_key)
        raise DuplicateChefAttribute, "An attribute '#{attr_key}' has already been defined on group '#{attributes[:name]}'"
      end

      self.chef_attributes[attr_key] = attr_value
    end

    def attributes
      super.merge!(recipes: self.recipes, roles: self.roles, chef_attributes: self.chef_attributes)
    end
  end
end
