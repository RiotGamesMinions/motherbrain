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
          register_component MB::ComponentInvoker.fabricate(klass, component)
        end

        klass.class_eval do
          desc("nodes ENVIRONMENT", "List all nodes grouped by Component and Group")
          define_method(:nodes) do |environment|
            assert_environment_exists(environment)
            
            plugin.send(:context).environment = environment

            MB.ui.say "Nodes in '#{environment}':"

            nodes = plugin.nodes.each do |component, groups|
              groups.each do |group, nodes|
                nodes.collect! { |node| "#{node[:automatic][:fqdn]} (#{node[:automatic][:ipaddress]})" }
              end
            end

            MB.ui.say nodes.to_yaml
          end

          if plugin.bootstrapper.present?
            desc("bootstrap ENVIRONMENT MANIFEST", "Bootstrap a manifest of node groups")
            define_method(:bootstrap) do |environment, manifest_file|
              manifest_file = File.expand_path(manifest_file)

              unless File.exist?(manifest_file)
                raise InvalidBootstrapManifest, "No bootstrap manifest found at: #{manifest_file}"
              end

              assert_environment_exists(environment)

              manifest = MultiJson.load(File.read(manifest_file))
              bootstrap_options = Hash.new

              MB.ui.say "Starting bootstrap of nodes on: #{environment}"
              p plugin.bootstrapper.run(manifest, bootstrap_options)
              MB.ui.say "Bootstrap finished"
            end
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
      MB.ui.say self.class.plugin.version
    end
  end
end
