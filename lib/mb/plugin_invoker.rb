module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class PluginInvoker < DynamicInvoker
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
          klass.register_component MB::ComponentInvoker.fabricate(klass, component)
        end

        klass.class_eval do
          desc("nodes ENVIRONMENT", "List all nodes grouped by Component and Group")
          define_method(:nodes) do |environment|
            MB.ui.say "Listing nodes in '#{environment}':"
            nodes = plugin.nodes(environment).each do |component, groups|
              groups.each do |group, nodes|
                nodes.collect! { |node| "#{node.public_hostname} (#{node.public_ipv4})" }
              end
            end
            MB.ui.say nodes.to_yaml
          end

          if plugin.bootstrap_routine.present?
            method_option :component_versions,
              type: :hash,
              desc: "The component versions to set with override attributes",
              aliases: "--components"
            method_option :cookbook_versions,
              type: :hash,
              desc: "The cookbook versions to set on the environment",
              aliases: "--cookbooks"
            method_option :environment_attributes,
              type: :hash,
              desc: "Any additional attributes to set on the environment",
              aliases: "--attributes"
            method_option :environment_attributes_file,
              type: :string,
              desc: "Any additional attributes to set on the environment via a json file.",
              aliases: "--attributes-file"
            method_option :force,
              type: :boolean,
              default: false,
              desc: "Perform bootstrap even if the environment is locked",
              aliases: "-f"
            desc("bootstrap ENVIRONMENT MANIFEST", "Bootstrap a manifest of node groups")
            define_method(:bootstrap) do |environment, manifest_file|
              boot_options = Hash.new.merge(options).deep_symbolize_keys
              manifest     = MB::Bootstrap::Manifest.from_file(manifest_file)

              job = Application.bootstrap(
                environment.freeze,
                manifest.freeze,
                plugin.freeze,
                boot_options.freeze
              )

              CliClient.new(job).display
            end

            method_option :component_versions,
              type: :hash,
              desc: "The component versions to set with override attributes",
              aliases: "--components"
            method_option :cookbook_versions,
              type: :hash,
              desc: "The cookbook versions to set on the environment",
              aliases: "--cookbooks"
            method_option :environment_attributes,
              type: :hash,
              desc: "Any additional attributes to set on the environment",
              aliases: "--attributes"
            method_option :environment_attributes_file,
              type: :string,
              desc: "Any additional attributes to set on the environment via a json file.",
              aliases: "--attributes-file"
            method_option :skip_bootstrap,
              type: :boolean,
              desc: "Nodes will be created and added to the Chef environment but not bootstrapped",
              default: false
            method_option :force,
              type: :boolean,
              default: false,
              desc: "Perform bootstrap even if the environment is locked"
            desc("provision ENVIRONMENT MANIFEST", "Create a cluster of nodes and add them to a Chef environment")
            define_method(:provision) do |environment, manifest_file|
              prov_options = Hash.new.merge(options).deep_symbolize_keys
              manifest     = Provisioner::Manifest.from_file(manifest_file)

              job = Application.provision(
                environment.freeze,
                manifest.freeze,
                plugin.freeze,
                prov_options.freeze
              )

              CliClient.new(job).display
            end

            method_option :component_versions,
              type: :hash,
              desc: "The component versions to set with override attributes",
              aliases: "--components"
            method_option :cookbook_versions,
              type: :hash,
              desc: "The cookbook versions to set on the environment",
              aliases: "--cookbooks"
            method_option :environment_attributes,
              type: :hash,
              desc: "Any additional attributes to set on the environment",
              aliases: "--attributes"
            method_option :environment_attributes_file,
              type: :string,
              desc: "Any additional attributes to set on the environment via a json file.",
              aliases: "--attributes-file"
            method_option :force,
              type: :boolean,
              default: false,
              desc: "Perform upgrade even if the environment is locked",
              aliases: "-f"
            desc("upgrade ENVIRONMENT", "Upgrade an environment to the specified versions")
            define_method(:upgrade) do |environment|
              upgrade_options = Hash.new.merge(options).deep_symbolize_keys

              job = Application.upgrade(
                environment.freeze,
                plugin.freeze,
                upgrade_options.freeze
              )

              CliClient.new(job).display
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
