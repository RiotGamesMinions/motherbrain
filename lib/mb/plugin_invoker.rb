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

            MB.ui.say "Listing nodes in '#{environment}':"
            nodes = plugin.nodes.each do |component, groups|
              groups.each do |group, nodes|
                nodes.collect! { |node| "#{node.public_hostname} (#{node.public_ipv4})" }
              end
            end
            MB.ui.say nodes.to_yaml
          end

          if plugin.bootstrap_routine.present?
            method_option :ssh_user,
              type: :string,
              desc: "A shell user that will login to each node and perform the bootstrap command on",
              aliases: "-u"
            method_option :ssh_password,
              type: :string,
              desc: "The password for the shell user that will perform the bootstrap",
              aliases: "-p"
            method_option :ssh_keys,
              type: :array,
              desc: "An array of keys (or a single key) to authenticate the ssh user with instead of a password"
            method_option :ssh_timeout,
              type: :numeric,
              desc: "The timeout for communicating to nodes over SSH"
            method_option :validator_client,
              type: :string,
              desc: "The name of the Chef validator client to use in bootstrapping"
            method_option :validator_path,
              type: :string,
              desc: "The filepath to the Chef validator client's private key to use in bootstrapping"
            method_option :bootstrap_proxy,
              type: :string,
              desc: "A proxy server for the node being bootstrapped"
            method_option :encrypted_data_bag_secret_path,
              type: :string,
              aliases: "--secret",
              desc: "The filepath to your organizations encrypted data bag secret key"
            method_option :sudo,
              type: :boolean,
              default: true,
              desc: "Should we execute the bootstrap with sudo?"
            desc("bootstrap ENVIRONMENT MANIFEST", "Bootstrap a manifest of node groups")
            define_method(:bootstrap) do |environment, manifest_file|
              assert_environment_exists(environment)
              manifest = MB::Bootstrap::Manifest.from_file(manifest_file)

              bootstrap_options = {
                environment: environment,
                server_url: context.chef_conn.server_url,
                ssh_user: options[:ssh_user] || context.config[:ssh_user],
                ssh_password: options[:ssh_password] || context.config[:ssh_password],
                ssh_keys: options[:ssh_keys] || context.config[:ssh_keys],
                ssh_timeout: options[:ssh_timeout] || context.config[:ssh_timeout],
                validator_client: options[:validator_client] || context.config[:chef_validator_client],
                validator_path: options[:validator_path] || context.config[:chef_validator_path],
                bootstrap_proxy: options[:bootstrap_proxy] || context.config[:chef_bootstrap_proxy],
                encrypted_data_bag_secret_path: options[:encrypted_data_bag_secret_path] || context.config[:chef_encrypted_data_bag_secret_path],
                sudo: options[:sudo] || context.config[:ssh_sudo]
              }

              MB.ui.say "Starting bootstrap of nodes on: #{environment}"
              MB.ui.say MB::Application.bootstrapper.bootstrap(manifest, plugin.bootstrap_routine, bootstrap_options)
              MB.ui.say "Bootstrap finished"
            end

            method_option :api_url,
              type: :string,
              desc: "URL to the Environment Factory API endpoint",
              required: true
            method_option :api_key,
              type: :string,
              desc: "API authentication key for the Environment Factory",
              required: true
            method_option :ssl_verify,
              type: :boolean,
              desc: "Should we verify SSL connections?",
              default: false
            method_option :skip_bootstrap,
              type: :boolean,
              desc: "Nodes will be created and added to the Chef environment but not bootstrapped",
              default: false
            method_option :ssh_user,
              type: :string,
              desc: "A shell user that will login to each node and perform the bootstrap command on",
              aliases: "-u"
            method_option :ssh_password,
              type: :string,
              desc: "The password for the shell user that will perform the bootstrap",
              aliases: "-p"
            method_option :ssh_keys,
              type: :array,
              desc: "An array of keys (or a single key) to authenticate the ssh user with instead of a password"
            method_option :ssh_timeout,
              type: :numeric,
              desc: "The timeout for communicating to nodes over SSH"
            method_option :validator_client,
              type: :string,
              desc: "The name of the Chef validator client to use in bootstrapping"
            method_option :validator_path,
              type: :string,
              desc: "The filepath to the Chef validator client's private key to use in bootstrapping"
            method_option :bootstrap_proxy,
              type: :string,
              desc: "A proxy server for the node being bootstrapped"
            method_option :encrypted_data_bag_secret_path,
              type: :string,
              aliases: "--secret",
              desc: "The filepath to your organizations encrypted data bag secret key"
            method_option :sudo,
              type: :boolean,
              default: true,
              desc: "Should we execute the bootstrap with sudo?"
            desc("provision ENVIRONMENT MANIFEST", "Create a cluster of nodes and add them to a Chef environment")
            define_method(:provision) do |environment, manifest_file|
              manifest = Provisioner::Manifest.from_file(manifest_file)
              provisioner_options = {
                api_url: options[:api_url],
                api_key: options[:api_key],
                ssl: {
                  verify: options[:ssl_verify]
                }
              }

              MB.ui.say "Provisioning nodes and adding them to: #{environment}"
              response = MB::Application.provisioner.provision(environment, manifest, plugin, provisioner_options)

              if response.ok?
                MB.ui.say "Provision finished"

                if options[:skip_bootstrap]
                  MB.ui.say "Skipping bootstrap"
                  exit 0
                end

                bootstrap_manifest = MB::Bootstrap::Manifest.from_provisioner(
                  response.body,
                  manifest,
                  Tempfile.new('bootstrap_manifest').path
                )
                bootstrap_manifest.save

                invoke(:bootstrap, [environment, bootstrap_manifest.path], options)
              else
                MB.ui.error response.body.to_s
                exit 1
              end
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
