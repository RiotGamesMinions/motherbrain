module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Upgrades a plugin by pinning cookbook versions and override attributes
    # (based on the plugin components' version attributes).
    #
    class Worker
      include Celluloid
      include Celluloid::Logger

      # TODO: Change usage of RIDLEY_OPT_KEYS to Ridley::Connection::OPTIONS.
      # see https://github.com/reset/ridley/pull/39.
      RIDLEY_OPT_KEYS = [
        :server_url,
        :client_name,
        :client_key,
        :organization,
        :validator_client,
        :validator_path,
        :encrypted_data_bag_secret_path,
        :thread_count,
        :ssl
      ].freeze

      # @return [String]
      attr_reader :environment_name

      # @return [Hash]
      attr_reader :options

      # @return [MotherBrain::Plugin]
      attr_reader :plugin

      # @param [String] environment_name
      #
      # @param [MotherBrain::Plugin] plugin
      #
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and
      #     perform the upgrade command on (required)
      #   * :password (String) the password for the shell user that will
      #     perform the upgrade
      #   * :keys (Array, String) an array of keys (or a single key) to
      #     authenticate the ssh user with instead of a password
      #   * :timeout (Float) [5.0] timeout value for SSH upgrade
      #   * :sudo (Boolean) [True] upgrade with sudo
      #
      # @option options [String] :server_url
      #   URL to the Chef API to upgrade the target node(s) to (required)
      #
      # @option options [String] :client_name
      #   name of the client used to authenticate with the Chef API (required)
      #
      # @option options [String] :client_key
      #   filepath to the client's private key used to authenticate with the Chef API (requirec)
      #
      # @option options [String] :organization
      #   the Organization to connect to. This is only used if you are connecting to
      #   private Chef or hosted Chef
      #
      # @option options [String] :validator_client
      #   the name of the Chef validator client to use in upgrading (requirec)
      #
      # @option options [String] :validator_path
      #   filepath to the validator used to upgrade the node (required)
      #
      # @option options [String] :encrypted_data_bag_secret_path (nil)
      #   filepath on your host machine to your organizations encrypted data bag secret
      #
      def initialize(environment_name, plugin, options = {})
        @environment_name = environment_name
        @plugin = plugin
        @options = options
      end

      # @raise [ComponentNotFound] if a component version is passed that does
      #   not have a corresponding component in the plugin
      #
      # @raise [ComponentNotVersioned] if a component version is passed that
      #   does not have a version attribute in the corresponding component
      #
      # @raise [EnvironmentNotFound] if the environment does not exist
      #
      def run
        assert_environment_exists

        ChefMutex.new("environment: #{environment_name}", options.slice(:force)).synchronize do
          set_component_versions if component_versions.any?
          set_cookbook_versions if cookbook_versions.any?

          if component_versions.any? or cookbook_versions.any?
            save_environment
            run_chef if nodes.any?
          end
        end
      end

      private

        # @raise [EnvironmentNotFound]
        def assert_environment_exists
          unless environment
            raise EnvironmentNotFound, "Environment '#{environment_name}' not found"
          end
        end

        # @return [Ridley::Connection]
        def chef_connection
          @chef_connection ||= Ridley::Connection.new(options.slice(*RIDLEY_OPT_KEYS))
        end

        # @return [Ridley::Environment]
        def environment
          @environment ||= chef_connection.environment.find(environment_name)
        end

        # @param [String] name
        #
        # @return [MotherBrain::Component]
        #
        # @raise [ComponentNotFound]
        def component(component_name)
          result = components.find { |component| component.name == component_name }

          unless result
            raise ComponentNotFound,
              "Component '#{component_name}' not found for plugin '#{plugin.name}'"
          end

          result
        end

        # @return [Hash]
        def component_versions
          options[:component_versions] || {}
        end

        # @return [Array<MotherBrain::Component>]
        def components
          plugin.components
        end

        # @return [Hash]
        def cookbook_versions
          options[:cookbook_versions] || {}
        end

        # @return [Hash]
        def override_attributes
          return @override_attributes if @override_attributes

          @override_attributes = {}

          component_versions.each do |component_name, version|
            @override_attributes[version_attribute(component_name)] = version
          end

          @override_attributes
        end

        # @return [Array<String>]
        def nodes
          result = plugin.nodes(environment_name).collect { |component, groups|
            groups.collect { |group, nodes|
              nodes.collect(&:public_hostname)
            }
          }.flatten.compact.uniq

          unless result.any?
            info "No nodes in environment '#{environment_name}'"
          end

          result
        end

        def run_chef
          info "Running chef on #{nodes}"

          nodes.map { |node|
            Application.node_querier.future.chef_run(node, options[:ssh])
          }.map(&:value)
        end

        def save_environment
          environment.save

          if cookbook_versions.any?
            info "Cookbook versions are now #{environment.cookbook_versions}"
          end

          if component_versions.any?
            info "Override attributes are now #{environment.override_attributes}"
          end

          @environment = nil
        end

        def set_component_versions
          info "Setting component versions #{component_versions}"

          set_override_attributes
        end

        def set_cookbook_versions
          info "Setting cookbook versions #{cookbook_versions}"

          environment.cookbook_versions.merge! cookbook_versions
        end

        def set_override_attributes
          info "Setting override attributes #{override_attributes}"

          environment.override_attributes.merge! override_attributes
        end

        # @param [String] component_name
        #
        # @return [String] the version attribute
        #
        # @raise [ComponentNotVersioned]
        def version_attribute(component_name)
          result = component(component_name).version_attribute

          unless result
            raise ComponentNotVersioned.new component_name
          end

          info "Component '#{component_name}' versioned with '#{result}'"

          result
        end
    end
  end
end
