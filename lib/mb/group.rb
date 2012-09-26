module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Group
    # @return [String]
    attr_reader :name

    # @return [Array<String>]
    attr_reader :recipes

    # @return [Array<String>]
    attr_reader :roles

    # @return [Hash]
    attr_reader :attributes

    # @param [Symbol, String] name
    def initialize(name, &block)
      @name = name.to_s
      @recipes = Array.new
      @roles = Array.new
      @attributes = Hash.new

      instance_eval(&block) if block_given?
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # @param [#to_s] value
    #
    # @return [Array<String>]
    def recipe(value)
      value = value.to_s
      if @recipes.include?(value)
        return @recipes
      end

      @recipes.push(value)
    end

    # @param [#to_s] value
    #
    # @return [Array<String>]
    def role(value)
      value = value.to_s
      if @roles.include?(value)
        return @roles
      end

      @roles.push(value)
    end

    # @param [#to_s] attribute
    # @param [Object] value
    def attribute(attribute, value)
      attribute = attribute.to_s

      if @attributes.has_key?(attribute)
        raise DuplicateAttribute, "An attribute '#{attribute}' has already been defined on group '#{name}'"
      end

      @attributes[attribute] = value
    end
  end
end
