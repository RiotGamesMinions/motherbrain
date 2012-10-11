module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Group
    include RealObject

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Returns an Array of Hashes containing the node data from Chef about each
    # node matching this instance of {Group}'s signature in the given environment.
    #
    # @param [String] environment
    #
    # @return [Array<String>]
    def nodes(environment)
      context.chef_conn.search(:node, search_query(environment))
    end

    # Returns an escape search query for Solr from the roles, rescipes, and chef_attributes
    # assigned to this Group.
    #
    # @return [String]
    def search_query(environment)
      items = ["chef_environment:#{environment}"]

      items += chef_attributes.collect do |key, value|
        key = key.gsub(/\./, "_")
        "#{attribute_escape(key)}:#{value}"
      end

      items += roles.collect do |role|
        item = "role[#{role}]"
        "run_list:#{solr_escape(item)}"
      end

      items += recipes.collect do |recipe|
        item = "recipe[#{recipe}]"
        "run_list:#{solr_escape(item)}"
      end

      items.join(' AND ')
    end

    # @param [#to_sym] name
    def chef_attribute(name)
      self.chef_attributes.fetch(name.to_sym, nil)
    end

    private

      def attribute_escape(value)
        value.gsub(/\./, "_")
      end

      def solr_escape(value)
        value.gsub(/[\:\[\]\+\-\!\^\(\)\{\}]/) { |x| "\\#{x}" }
      end
  end

  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class GroupProxy
    include ProxyObject

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
      @chef_attributes ||= HashWithIndifferentAccess.new
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
