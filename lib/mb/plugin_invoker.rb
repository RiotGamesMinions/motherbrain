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
              alises: "-secret",
              desc: "The filepath to your organizations encrypted data bag secret key"
            method_option :sudo,
              type: :boolean,
              default: true,
              desc: "Should we execute the bootstrap with sudo?"
            desc("bootstrap ENVIRONMENT MANIFEST", "Bootstrap a manifest of node groups")
            define_method(:bootstrap) do |environment, manifest_file|
              manifest_file = File.expand_path(manifest_file)

              unless File.exist?(manifest_file)
                raise InvalidBootstrapManifest, "No bootstrap manifest found at: #{manifest_file}"
              end

              assert_environment_exists(environment)

              manifest = MultiJson.load(File.read(manifest_file))

              bootstrap_options = {
                environment: environment,
                server_url: context.chef_conn.server_url,
                ssh_user: options[:ssh_user] || context.config[:ssh_user],
                ssh_password: options[:ssh_password] || context.config[:ssh_password],
                ssh_keys: options[:ssh_keys] || context.config[:ssh_keys],
                validator_client: options[:validator_client] || context.config[:chef_validator_client],
                validator_path: options[:validator_path] || context.config[:chef_validator_path],
                bootstrap_proxy: options[:bootstrap_proxy] || context.config[:chef_bootstrap_proxy],
                encrypted_data_bag_secret_path: options[:encrypted_data_bag_secret_path] || context.config[:chef_encrypted_data_bag_secret_path],
                sudo: options[:sudo] || context.config[:ssh_sudo]
              }

              MB.ui.say "Starting bootstrap of nodes on: #{environment}"
              MB.ui.say plugin.bootstrapper.run(manifest, bootstrap_options)
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
