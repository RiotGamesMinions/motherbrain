module MotherBrain
  class Plugin
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Components
      # @return [Hash]
      def components
        @components ||= Hash.new
      end

      def component(name, &block)
        add_component Component.new(name, &block)
      end

      private

        # @param [Component] component
        def add_component(component)
          self.components[component.id] = component
        end

        # @param [Component] component
        def get_component(component)
          self.components.fetch(component.id, nil)
        end
    end
  end
end
