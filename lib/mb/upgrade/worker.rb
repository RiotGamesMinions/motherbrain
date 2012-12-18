module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Upgrades a plugin by pinning cookbook versions and override attributes
    # (based on the plugin components' version attributes).
    #
    class Worker
      extend Forwardable

      include Celluloid
      include MB::Locks
      include MB::Logging

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
      # @option options [Hash] component_versions
      #   Hash of components and the versions to set them to
      #
      # @option options [Hash] cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      #
      # @option options [Boolean] :force
      #   Force any locks to be overwritten
      #
      def initialize(environment_name, plugin, options = {})
        @environment_name = environment_name
        @plugin           = plugin
        @options          = options
      end

      # @raise [ComponentNotFound] if a component version is passed that does
      #   not have a corresponding component in the plugin
      #
      # @raise [ComponentNotVersioned] if a component version is passed that
      #   does not have a version attribute in the corresponding component
      #
      # @raise [EnvironmentNotFound] if the environment does not exist
      #
      # @return [Job]
      def run(job)
        job.transition(:running)
        assert_environment_exists

        chef_synchronize(chef_environment: environment_name, force: options[:force]) do
          set_component_versions if component_versions.any?
          set_cookbook_versions if cookbook_versions.any?

          if component_versions.any? or cookbook_versions.any?
            save_environment
            run_chef if nodes.any?
          end
        end

        job.transition(:success)
      rescue EnvironmentNotFound => e
        log.fatal { "environment not found: #{e}" }
        job.transition(:failure, e)
      rescue => e
        log.fatal { "unknown error occured: #{e}"}
        job.transition(:failure, "internal error")
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
          @chef_connection ||= Application.ridley
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
            log.info "No nodes in environment '#{environment_name}'"
          end

          result
        end

        def run_chef
          log.info "Running chef on #{nodes}"

          nodes.map { |node|
            Application.node_querier.future.chef_run(node)
          }.map(&:value)
        end

        def save_environment
          environment.save

          if cookbook_versions.any?
            log.info "Cookbook versions are now #{environment.cookbook_versions}"
          end

          if component_versions.any?
            log.info "Override attributes are now #{environment.override_attributes}"
          end

          @environment = nil
        end

        def set_component_versions
          log.info "Setting component versions #{component_versions}"

          set_override_attributes
        end

        def set_cookbook_versions
          log.info "Setting cookbook versions #{cookbook_versions}"

          environment.cookbook_versions.merge! cookbook_versions
        end

        def set_override_attributes
          log.info "Setting override attributes #{override_attributes}"

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

          log.info "Component '#{component_name}' versioned with '#{result}'"

          result
        end
    end
  end
end
