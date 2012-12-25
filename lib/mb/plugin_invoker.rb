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
          register_component MB::ComponentInvoker.fabricate(klass, component)
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
            method_option :force,
              type: :boolean,
              default: false,
              desc: "Perform bootstrap even if the environment is locked"
            desc("bootstrap ENVIRONMENT MANIFEST", "Bootstrap a manifest of node groups")
            define_method(:bootstrap) do |environment, manifest_file|
              manifest = MB::Bootstrap::Manifest.from_file(manifest_file)

<<<<<<< HEAD
              bootstrap_options = {
                environment: environment,
                server_url: Application.ridley.server_url,
                client_name: Application.ridley.client_name,
                client_key: Application.ridley.client_key,
                validator_client: options[:validator_client] || Application.config[:chef][:validator_client],
                validator_path: options[:validator_path] || Application.config[:chef][:validator_path],
                bootstrap_proxy: options[:bootstrap_proxy] || Application.config[:chef][:bootstrap_proxy],
                encrypted_data_bag_secret_path: options[:encrypted_data_bag_secret_path] || Application.config[:chef][:encrypted_data_bag_secret_path],
                ssh: {
                  user: options[:ssh_user] || Application.config[:ssh][:user],
                  password: options[:ssh_password] || Application.config[:ssh][:password],
                  keys: options[:ssh_keys] || Application.config[:ssh][:keys],
                  timeout: options[:ssh_timeout] || Application.config[:ssh][:timeout],
                  sudo: options[:sudo] || Application.config[:ssh][:sudo]
                },
                ssl: {
                  verify: options[:ssl_verify] || Application.config[:ssl][:verify]
                },
                force: options[:force]
              }

              job = MB::Application.bootstrap(environment, manifest, plugin.bootstrap_routine, bootstrap_options)

              CliClient.new(job).display
=======
              MB::Application.bootstrap(
                environment.freeze,
                manifest.freeze,
                plugin.bootstrap_routine.freeze,
                options.freeze
              )
>>>>>>> plugin invoker reflects simplified passed options
            end

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
              manifest = Provisioner::Manifest.from_file(manifest_file)
              job      = Provisioner::Manager.instance.provision(environment, manifest, plugin)

              CliClient.new(job).display

              return if options[:skip_bootstrap]

              bootstrap_manifest = MB::Bootstrap::Manifest.from_provisioner(
                job.result,
                manifest,
                Tempfile.new('bootstrap_manifest').path
              )
              bootstrap_manifest.save

              invoke(:bootstrap, [environment, bootstrap_manifest.path], options)
            end

            method_option :component_versions,
              type: :hash,
              desc: "The component versions to set with override attributes",
              aliases: "--components"
            method_option :cookbook_versions,
              type: :hash,
              desc: "The cookbook versions to set on the environment",
              aliases: "--cookbooks"
            method_option :force,
              type: :boolean,
              default: false,
              desc: "Perform upgrade even if the environment is locked",
              aliases: "-f"
            desc("upgrade ENVIRONMENT", "Upgrade an environment to the specified versions")
            define_method(:upgrade) do |environment|
              job = MB::Application.upgrade(environment, plugin, options)
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
