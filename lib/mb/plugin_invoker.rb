module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class PluginInvoker < InvokerBase
    include DynamicInvoker

    class << self
      # Return the plugin used to generate the anonymous CLI class
      #
      # @return [MotherBrain::Plugin]
      attr_reader :plugin

      # @param [MotherBrain::Plugin] plugin
      #
      # @return [PluginInvoker]
      def fabricate(plugin)
        klass = Class.new(self)
        klass.namespace(plugin.name)
        klass.set_plugin(plugin)

        plugin.commands.each do |command|
          klass.define_command(command)
        end

        plugin.components.each do |component|
          register_component MotherBrain::ComponentInvoker.fabricate(klass, component)
        end

        klass.class_eval do
          desc("nodes ENVIRONMENT", "List all nodes grouped by Component and Group")
          define_method(:nodes) do |environment|
            assert_environment_exists(environment)
            
            plugin.send(:context).environment = environment

            MotherBrain.ui.say "Nodes in '#{environment}':"

            nodes = plugin.nodes.each do |component, groups|
              groups.each do |group, nodes|
                nodes.collect! { |node| "#{node[:automatic][:fqdn]} (#{node[:automatic][:ipaddress]})" }
              end
            end

            MotherBrain.ui.say nodes.to_yaml
          end
        end

        klass
      end

      # @param [MotherBrain::ComponentInvoker] klass
      def register_component(klass)
        self.register klass, klass.component.name, "#{klass.component.name} [COMMAND]", klass.component.description
      end

      protected

        # Set the plugin used to generate the anonymous CLI class. Can be
        # retrieved later by calling MyClass::plugin.
        #
        # @param [MotherBrain::Plugin] plugin
        def set_plugin(plugin)
          @plugin = plugin
        end
    end

    desc "version", "Display plugin version"
    def version
      MotherBrain.ui.say self.class.plugin.version
    end
  end
end
