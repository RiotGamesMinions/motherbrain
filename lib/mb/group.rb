module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Group
    attr_reader :name
    attr_reader :recipes
    attr_reader :roles

    # @param [Symbol, String] name
    def initialize(name, &block)
      @name = name.to_s
      @recipes = Array.new
      @roles = Array.new

      instance_eval(&block) if block_given?
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
  end
end
