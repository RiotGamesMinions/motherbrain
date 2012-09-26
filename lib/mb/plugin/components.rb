module MotherBrain
  class Plugin
    module Components
      # @return [Hash]
      def components
        @components ||= Hash.new
      end

      def component(name, &block)
        add Component.new(name, &block)
      end

      private

        # @param [Component] component
        def add(component)
          self.components[component.id] = component
        end

        # @param [Component] component
        def get(component)
          self.components.fetch(component.id, nil)
        end
    end
  end
end
