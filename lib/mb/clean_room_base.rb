module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CleanRoomBase
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

    # @param [Object] real_model
    def initialize(real_model, &block)
      @real_model = real_model
    end

    private

      attr_reader :real_model

      def set_attribute(name, value)
        real_model.send("#{name}=", value)
      end

      def method_missing(method_name, *args, &block)
        ErrorHandler.wrap PluginSyntaxError,
          backtrace: caller,
          method_name: method_name,
          text: "'#{method_name}' is not a valid keyword"
      end
  end
end
