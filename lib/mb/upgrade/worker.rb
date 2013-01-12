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
      include MB::Mixin::VersionLocking

      # @return [String]
      attr_reader :environment_name

      # @return [MotherBrain::Job]
      attr_reader :job

      # @return [Hash]
      attr_reader :options

      # @return [MotherBrain::Plugin]
      attr_reader :plugin

      # @param [String] environment_name
      #
      # @param [MotherBrain::Plugin] plugin
      #
      # @param [MotherBrain::Job] job
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
      def initialize(environment_name, plugin, job, options = {})
        @environment_name = environment_name
        @plugin           = plugin
        @job              = job
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
      def run
        job.status = "Starting"
        job.report_running

        assert_environment_exists

        chef_synchronize(chef_environment: environment_name, force: options[:force], job: job) do
          if component_versions.any?
            job.status = "Setting component versions"
            set_component_versions(environment_name, plugin, component_versions)
          end

          if cookbook_versions.any?
            job.status = "Setting cookbook versions"
            set_cookbook_versions(environment_name, cookbook_versions)
          end

          if component_versions.any? or cookbook_versions.any?
            run_chef if nodes.any?
          end
        end

        job.status = "Finishing up"
        job.report_success
      rescue EnvironmentNotFound => error
        log.fatal { "environment not found: #{error}" }
        job.report_failure(error)
      rescue => error
        log.fatal { "unknown error occured: #{error}"}
        job.report_failure("internal error")
      end

      private

        # @raise [EnvironmentNotFound]
        def assert_environment_exists
          unless chef_connection.environment.find(environment_name)
            raise EnvironmentNotFound, "Environment '#{environment_name}' not found"
          end
        end

        # @return [Ridley::Connection]
        def chef_connection
          Application.ridley
        end

        # @return [Hash]
        def component_versions
          options[:component_versions] || {}
        end

        # @return [Hash]
        def cookbook_versions
          options[:cookbook_versions] || {}
        end

        # @return [Array<String>]
        def nodes
          return @nodes if @nodes

          job.status = "Looking for nodes"

          @nodes = plugin.nodes(environment_name).collect { |component, groups|
            groups.collect { |group, nodes|
              nodes.collect(&:public_hostname)
            }
          }.flatten.compact.uniq

          unless @nodes.any?
            log.info "No nodes in environment '#{environment_name}'"
          end

          @nodes
        end

        def run_chef
          log.info "Running Chef on #{nodes}"
          job.status = "Running Chef on nodes"

          nodes.map { |node|
            Application.node_querier.future.chef_run(node)
          }.map(&:value)
        end
    end
  end
end
