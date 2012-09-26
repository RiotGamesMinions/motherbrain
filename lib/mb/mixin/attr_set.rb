module MotherBrain
  module Mixin
    # @author Jamie Winsor <jamie@vialstudios.com>
    module AttrSet
      class << self
        # @param [Object] value
        # @param [Hash] map
        #
        # @raise [ValidationFailed]
        #
        # @return [Boolean]
        def validate(key, value, map)
          map.each do |type, requirements|
            fun = VALIDATE_FUNCTIONS.fetch(type)
            fun.call(key, value, requirements)
          end

          true
        end

        private

          # @return [Proc]
          def validate_kind_of
            Proc.new do |key, value, types|
              valid = false
              types = Array(types)

              types.each do |type|
                valid = value.is_a?(type)

                break if valid
              end

              unless valid
                types = types.collect { |x| "'#{x}'" }
                raise MB::ValidationFailed, "Expected the value of '#{key}' to be a #{types.join(', ')} but was '#{value.class}'"
              end
            end
          end

          # @return [Proc]
          def validate_required
            Proc.new do |key, value, required|
              return unless required

              if value.nil?
                raise MB::ValidationFailed, "A required value for '#{key}' was expected but missing"
              end
            end
          end

          # @return [Proc]
          def validate_respond_to
            Proc.new do |key, value, methods|
              valid = false
              methods = Array(methods)

              methods.each do |method|
                valid = value.respond_to?(method.to_sym)

                break if valid
              end

              unless valid
                methods = methods.collect { |x| "'#{x}'" }
                raise MB::ValidationFailed, "Expected the value of '#{key}' to respond to #{methods.join(', ')} but didn't"
              end
            end
          end
      end

      VALIDATE_FUNCTIONS = {
        kind_of: validate_kind_of,
        required: validate_required,
        respond_to: validate_respond_to
      }.freeze

      # @return [Hash]
      def attributes
        @attributes ||= Hash.new
      end

      private

        # @param [Symbol] key
        # @param [Object] value
        # @param [Hash] validation
        #
        # @return [Object]
        def set(key, value, validation)
          AttrSet.validate(key, value, validation)

          self.attributes[key.to_sym] = value
        end
    end
  end
end
