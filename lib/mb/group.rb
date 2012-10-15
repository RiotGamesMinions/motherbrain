module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Group < ContextualModel
    attr_reader :roles
    attr_reader :recipes
    attr_reader :chef_attributes

    # @param [String] environment
    # @param [Ridley::Connection] chef_conn
    def initialize(context, &block)
      super(context)
      @recipes         = Set.new
      @roles           = Set.new
      @chef_attributes = HashWithIndifferentAccess.new

      if block_given?
        dsl_eval(&block)
      end
    end

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
    def nodes
      chef_conn.search(:node, search_query)
    end

    # Returns an escape search query for Solr from the roles, rescipes, and chef_attributes
    # assigned to this Group.
    #
    # @return [String]
    def search_query
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

    def add_role(name)
      self.roles.add(name)
    end

    def add_recipe(name)
      self.recipes.add(name)
    end

    def add_chef_attribute(key, value)
      if chef_attribute(key).present?
        raise DuplicateChefAttribute, "An attribute '#{key}' has already been defined on group '#{attributes[:name]}'"
      end

      self.chef_attributes[key] = value
    end

    # @param [#to_sym] name
    def chef_attribute(name)
      self.chef_attributes.fetch(name.to_sym, nil)
    end

    def dsl_eval(&block)
      self.attributes = CleanRoom.new(context, self, &block).attributes
      self
    end

    private

      def attribute_escape(value)
        value.gsub(/\./, "_")
      end

      def solr_escape(value)
        value.gsub(/[\:\[\]\+\-\!\^\(\)\{\}]/) { |x| "\\#{x}" }
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < ContextualModel
      def initialize(context, group, &block)
        super(context)
        @group = group

        instance_eval(&block)
      end

      # @param [String] value
      def name(value)
        set(:name, value, kind_of: String, required: true)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String)
      end

      # @param [#to_s] value
      #
      # @return [Set<String>]
      def recipe(value)
        group.add_recipe(value.to_s)
      end

      # @param [#to_s] value
      #
      # @return [Set<String>]
      def role(value)
        group.add_role(value.to_s)
      end

      # @param [#to_s] attr_key
      # @param [Object] attr_value
      def chef_attribute(attr_key, attr_value)
        group.add_chef_attribute(attr_key, attr_value)
      end

      protected

        attr_reader :group
    end
  end
end
