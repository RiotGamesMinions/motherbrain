module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class AbstractGear
    class << self
      # The identifier for the Gear. The keyword is automatically populated based on the name
      # of the Class including {MotherBrain::Gear}. The keyword must be unique among the other
      # registered Gears. Also used to define a Gear in the plugin DSL.
      #
      # @return [Symbol]
      attr_reader :keyword

      # Register the gear with {MotherBrain::Gear} with the given keyword. This is how a gear is
      # identified within a plugin.
      #
      # @param [#to_sym] keyword
      def register_gear(keyword)
        @keyword = keyword.to_sym
        Gear.register(self)
      end
    end

    include Chozo::VariaModel

    def run(environment, *args)
      raise AbstractFunction, "#run(environment, *args) must be implemented on #{self.class}"
    end
  end
end
