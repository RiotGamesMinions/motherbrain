module MotherBrain
  module Cli
    module SubCommand
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
              include MB::Mixin::Services
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
                nodes = plugin.nodes(environment).each do |component, groups|
                  groups.each do |group, nodes|
                    nodes.collect! { |node| "#{node.public_hostname} (#{node.public_ipv4})" }
                  end
                end

                ui.say "\n"
                ui.say "** listing nodes in #{environment}:"
                ui.say "\n"
                ui.say nodes.to_yaml
              end

              if plugin.bootstrap_routine.present?
                method_option :chef_version,
                  type: :string,
                  desc: "The version of Chef to bootstrap the node(s) with"
                method_option :component_versions,
                  type: :hash,
                  desc: "The component versions to set with default attributes",
                  aliases: "--components"
                method_option :cookbook_versions,
                  type: :hash,
                  hidden: true,
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
                method_option :template,
                  type: :string,
                  desc: "Path to bootstrap template (ERB)"
                method_option :force,
                  type: :boolean,
                  default: false,
                  desc: "Perform bootstrap even if the environment is locked",
                  aliases: "-f"
                desc("bootstrap MANIFEST", "Bootstrap a manifest of node groups")
                define_method(:bootstrap) do |manifest_file|
                  boot_options = Hash.new.merge(options).deep_symbolize_keys
                  manifest     = MB::Bootstrap::Manifest.from_file(manifest_file)

                  cookbooks_option_deprecated(options)

                  job = bootstrapper.async_bootstrap(
                    environment.freeze,
                    manifest.freeze,
                    plugin.freeze,
                    boot_options.freeze
                  )

                  CliClient.new(job).display
                end

                method_option :chef_version,
                  type: :string,
                  desc: "The version of Chef to bootstrap the node(s) with"
                method_option :component_versions,
                  type: :hash,
                  desc: "The component versions to set with default attributes",
                  aliases: "--components"
                method_option :cookbook_versions,
                  type: :hash,
                  hidden: true,
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
                method_option :template,
                  type: :string,
                  desc: "Path to bootstrap template (ERB)"
                method_option :force,
                  type: :boolean,
                  default: false,
                  desc: "Perform bootstrap even if the environment is locked"
                desc("provision MANIFEST", "Create a cluster of nodes and add them to a Chef environment")
                define_method(:provision) do |manifest_file|
                  prov_options = Hash.new.merge(options).deep_symbolize_keys
                  manifest     = Provisioner::Manifest.from_file(manifest_file)

                  cookbooks_option_deprecated(options)

                  job = provisioner.async_provision(
                    environment.freeze,
                    manifest.freeze,
                    plugin.freeze,
                    prov_options.freeze
                  )

                  CliClient.new(job).display
                end

                method_option :cluster_override,
                  type: :boolean,
                  default: false,
                  desc: "Sets the service operation to execute at the environment level"
                method_option :force,
                  type: :boolean,
                  default: false,
                  desc: "Perform service change even if the environment is locked",
                  aliases: "-f"
                method_option :only,
                  type: :array,
                  default: nil,
                  desc: "Run command only on the given hostnames or IPs",
                  aliases: "-o"
                desc("service [COMPONENT].[SERVICE] [STATE]", "Change the specified service to a new state")
                define_method(:service) do |service, state|
                  service_options = Hash.new.merge(options).deep_symbolize_keys
                  service_options[:node_filter] = service_options.delete(:only)

                  job = plugin_manager.async_change_service_state(
                    service.freeze,
                    plugin.freeze,
                    environment.freeze,
                    state.freeze,
                    true,
                    service_options
                  )
                  CliClient.new(job).display
                end

                method_option :component_versions,
                  type: :hash,
                  desc: "The component versions to set with default attributes",
                  aliases: "--components"
                method_option :cookbook_versions,
                  type: :hash,
                  hide: true,
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
                method_option :concurrency,
                  type: :numeric,
                  desc: "The max number of nodes to upgrade concurrently.",
                  aliases: "-C"
                method_option :stack_order,
                  type: :boolean,
                  desc: "The upgrade will be constrained to the order defined in the plugin's stack_order."
                desc("upgrade", "Upgrade an environment to the specified versions")
                define_method(:upgrade) do
                  upgrade_options = Hash.new.merge(options).deep_symbolize_keys

                  cookbooks_option_deprecated(options)

                  job = upgrade_manager.async_upgrade(
                    environment.freeze,
                    plugin.freeze,
                    upgrade_options.freeze
                  )

                  CliClient.new(job).display
                end

                desc("attributes", "View available attributes for plugin.")
                define_method(:attributes) do
                  ui.say "\n"
                  ui.say "** listing attributes for #{plugin}:"
                  ui.say "\n"
                  ui.say plugin.metadata.attributes.to_yaml
                end
              end

              no_commands do
                def cookbooks_option_deprecated(options)
                  if options[:cookbook_versions]
                    ui.deprecated "--cookbooks option is deprecated in favor of loading versions from Berksfile.lock"
                  end
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
