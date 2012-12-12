module MotherBrain
  module Upgrade
    class Worker
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

      attr_reader :environment, :plugin, :options

      def initialize(environment, plugin, options = {})
        @environment = environment
        @plugin = plugin
        @options = options
      end

      def run
        assert_environment_exists

        set_component_versions if component_versions
        set_cookbook_versions if cookbook_versions

        save_environment
        run_chef
      end

      private

      def component_versions
        options['component_versions'] || {}
      end

      def cookbook_versions
        options['cookbook_versions'] || {}
      end

      def override_attributes
        return @override_attributes if @override_attributes

        @override_attributes = {}

        component_versions.each do |component_name, version|
          @override_attributes[version_attribute(component_name)] = version
        end

        @override_attributes
      end

      def component(name)
        result = components.find { |component| component.name == name }

        unless result
          raise ComponentNotFound,
            "Component '#{component_name}' not found for plugin '#{plugin.name}'"
        end

        result
      end

      def version_attribute(component_name)
        result = component(component_name).version_attribute

        unless result
          raise ComponentNotVersioned.new component_name
        end

        MB.ui.say "Component '#{component_name}' versioned as '#{result}'"

        result
      end

      def components
        plugin.components
      end

      def nodes
        result = plugin.nodes(environment).collect { |group, node| node['default'][0].public_hostname }

        unless result.any?
          MB.ui.say "No nodes in environment '#{environment}'"
        end

        result
      end

      def chef_environment
        @chef_environment ||= chef_connection.environment.find(environment)
      end

      def set_component_versions
        MB.ui.say "Setting cookbook versions #{cookbook_versions}"

        set_override_attributes
      end

      def set_override_attributes
        MB.ui.say "Setting override attributes #{override_attributes}"

        chef_environment.override_attributes.merge! override_attributes
      end

      def set_cookbook_versions
        MB.ui.say "Setting cookbook versions #{cookbook_versions}"

        chef_environment.cookbook_versions.merge! cookbook_versions
      end

      def save_environment
        chef_environment.save
        @chef_environment = nil
      end

      def run_chef
        MB.ui.say "Running chef on #{nodes}"

        nodes.map { |node|
          Application.node_querier.future.chef_run(node)
        }.map(&:value)
      end

      def assert_environment_exists
        unless chef_environment
          raise EnvironmentNotFound, "Environment '#{environment}' not found"
        end
      end

      def chef_connection
        @chef_connection = Ridley::Connection.new(options.slice(*RIDLEY_OPT_KEYS))
      end
    end
  end
end
