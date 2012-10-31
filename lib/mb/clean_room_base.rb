module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CleanRoomBase < ContextualModel
    class << self
      # Create a DSL writer function that will assign the a given value
      # to the real object of this clean room.
      #
      # @param [Symbol] attribute
      def dsl_attr_writer(attribute)
        class_eval do
          define_method(attribute) do |value|
            set_attribute(attribute, value)
          end
        end
      end
    end

    # @param [MB::Context] context
    # @param [MB::ContextualModel] real_model
    #
    # @return [MB::ContextualModel]
    def initialize(context, real_model, &block)
      super(context)
      @real_model = real_model
    end

    private

      attr_reader :real_model

      def set_attribute(name, value)
        real_model.send("#{name}=", value)
      end
  end
end
