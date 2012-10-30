module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CleanRoomBase < ContextualModel
    class << self
      # Create a DSL writer function that will assign the a given value
      # to the binding of this clean room.
      #
      # @param [Symbol] attribute
      def bind_attribute(attribute)
        class_eval do
          define_method attribute do |value|
            set_attribute(attribute, value)
          end
        end
      end
    end

    # @param [MB::Context] context
    # @param [MB::ContextualModel] binding
    #
    # @return [MB::ContextualModel]
    def initialize(context, binding, &block)
      super(context)
      @binding = binding

      instance_eval(&block)
      binding
    end

    private

      attr_reader :binding

      def set_attribute(name, value)
        binding.send("#{name}=", value)
      end
  end
end
