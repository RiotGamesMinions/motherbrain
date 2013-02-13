module MotherBrain
  module Cli
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      #
      # A set of component tasks collected into a SubCommand to be registered with the
      # CliGateway. This class should not be instantiated, configured, and used by itself.
      # Use {SubCommand::Plugin.fabricate} to create an anonymous class of this type.
      #
      # @api private
      class Plugin < SubCommand::Base
        class << self
          extend Forwardable

          def_delegator :plugin, :description

          # Return the plugin used to generate the anonymous CLI class
          #
          # @return [MotherBrain::Plugin]
          attr_reader :plugin

          # @param [MotherBrain::Plugin] plugin
          #
          # @return [SubCommand::Plugin]
          def fabricate(plugin)
            environment = CliGateway.invoked_opts[:environment]

            klass = Class.new(self) do
              set_plugin(plugin)
            end

            plugin.commands.each do |command|
              klass.define_task(command)
            end

            plugin.components.each do |component|
              klass.register_subcommand MB::Cli::SubCommand.new(component)
            end

            klass.class_eval do
              desc("nodes", "List all nodes grouped by Component and Group")
              define_method(:nodes) do
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
                desc("bootstrap MANIFEST", "Bootstrap a manifest of node groups")
                define_method(:bootstrap) do |manifest_file|
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
                desc("provision MANIFEST", "Create a cluster of nodes and add them to a Chef environment")
                define_method(:provision) do |manifest_file|
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
                desc("upgrade", "Upgrade an environment to the specified versions")
                define_method(:upgrade) do
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

          # Set the plugin for this instance of the class and tailor the class for the
          # given plugin.
          #
          # @param [MotherBrain::Plugin] plugin
          def set_plugin(plugin)
            self.namespace(plugin.name)
            @plugin = plugin
          end
        end
      end
    end
  end
end
