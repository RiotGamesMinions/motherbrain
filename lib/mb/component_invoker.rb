module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ComponentInvoker < DynamicInvoker
    class << self
      # Return the component used to generate the anonymous Invoker class
      #
      # @return [MotherBrain::Component]
      attr_reader :component

      # @param [MotherBrain::PluginInvoker] plugin_invoker
      # @param [MotherBrain::Component] component
      #
      # @return [ComponentInvoker]
      def fabricate(plugin_invoker, component)
        klass = Class.new(self)
        klass.namespace(component.name)
        klass.set_component(component)

        component.commands.each do |command|
          klass.define_command(command)
        end

        klass.class_eval do
          desc("nodes ENVIRONMENT", "List all nodes grouped by Group")
          define_method(:nodes) do |environment|
            MB.ui.say "Listing nodes for '#{component.name}' in '#{environment}':"
            nodes = component.nodes(environment).each do |group, nodes|
              nodes.collect! { |node| "#{node.public_hostname} (#{node.public_ipv4})" }
            end
            MB.ui.say nodes.to_yaml
          end
        end

        klass
      end

      protected

        # Set the component used to generate the anonymous Invoker class. Can be
        # retrieved later by calling MyClass::component.
        #
        # @param [MotherBrain::Component] component
        def set_component(component)
          @component = component
        end
    end
  end
end
