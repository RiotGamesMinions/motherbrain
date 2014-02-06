module MotherBrain
  class Group
    include VariaModel

    attribute :name,
      type: String,
      required: true

    # @return [Set]
    attr_reader :roles
    # @return [Set]
    attr_reader :recipes
    # @return [Hashie::Mash]
    attr_reader :chef_attributes

    # @param [#to_s] name
    def initialize(name, &block)
      set_attribute(:name, name.to_s)
      @recipes         = Set.new
      @roles           = Set.new
      @chef_attributes = Hashie::Mash.new

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Returns an Array Ridley::Node objects from Chef that match this {Group}'s
    # signature.
    #
    # A signature is any combination of a recipe(s) or role(s) in a node's run_list or
    # an attribute(s) on a node.
    #
    # @param [#to_s] environment
    #
    # @return [Array<Ridley::Node>]
    def nodes(environment)
      Application.ridley.partial_search(:node, search_query(environment), [ "public_ipv4", "public_hostname" ])
    end

    # Returns an escape search query for Solr from the roles, rescipes, and chef_attributes
    # assigned to this Group.
    #
    # @param [#to_s] environment
    #
    # @return [String]
    def search_query(environment)
      items = ["chef_environment:#{environment}"]

      items += chef_attributes.collect do |key, value|
        key = key.gsub(/\./, "_")
        "#{attribute_escape(key)}:#{value}"
      end

      items += roles.collect { |role| "roles:#{solr_escape(role)}" }
      items += recipes.collect { |recipe| "recipes:#{solr_escape(recipe)}" }

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
        raise DuplicateChefAttribute, "An attribute '#{key}' has already been defined on group '#{_attributes_[:name]}'"
      end

      self.chef_attributes[key] = value
    end

    # @param [#to_sym] name
    def chef_attribute(name)
      self.chef_attributes.fetch(name.to_sym, nil)
    end

    # Combines the recipes and roles of this group into a run_list that can be passed to
    # Chef or Ridley
    #
    #   [ "role[web_server]", "recipe[nginx::default]" ]
    #
    # @return [Array<String>]
    def run_list
      self.roles.collect { |role| "role[#{role}]" } +
        self.recipes.collect { |recipe| "recipe[#{recipe}]" }
    end

    # Indicates whether the run list contains the recipe
    #
    # @return [TrueClass, FalseClass]
    def includes_recipe?(recipe)
      # todo expand roles?
      self.run_list.include?("recipe[#{recipe}]")
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(self).instance_eval(&block)
      end

      def attribute_escape(value)
        value.gsub(/\./, "_")
      end

      def solr_escape(value)
        value.gsub(/[\:\[\]\+\!\^\(\)\{\}]/) { |x| "\\#{x}" }
      end

    # @api private
    class CleanRoom < CleanRoomBase
      # @param [#to_s] value
      #
      # @return [Set<String>]
      def recipe(value)
        real_model.add_recipe(value.to_s)
      end

      # @param [#to_s] value
      #
      # @return [Set<String>]
      def role(value)
        real_model.add_role(value.to_s)
      end

      # @param [#to_s] attr_key
      # @param [Object] attr_value
      def chef_attribute(attr_key, attr_value)
        real_model.add_chef_attribute(attr_key, attr_value)
      end
    end
  end
end
