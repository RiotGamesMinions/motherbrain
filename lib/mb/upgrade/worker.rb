module MotherBrain
  module Upgrade
    # Upgrades a plugin by pinning cookbook versions and default attributes
    # (based on the plugin components' version attributes).
    class Worker
      extend Forwardable

      include Celluloid
      include MB::Logging
      include MB::Mixin::Locks
      include MB::Mixin::AttributeSetting
      include MB::Mixin::Services

      # @return [String]
      attr_reader :environment_name

      # @return [MotherBrain::Job]
      attr_reader :job

      # @return [Hash]
      attr_reader :options

      # @return [MotherBrain::Plugin]
      attr_reader :plugin

      # @param [String] environment_name
      # @param [MotherBrain::Plugin] plugin
      # @param [MotherBrain::Job] job
      #
      # @option options [Hash] component_versions
      #   Hash of components and the versions to set them to
      # @option options [Hash] cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] environment_attributes
      #   any additional attributes to set on the environment
      # @option options [String] environment_attributes_file
      #   any additional attributes to set on the environment via a json file
      # @option options [Boolean] :force
      #   Force any locks to be overwritten
      def initialize(job, environment_name, plugin, options = {})
        @job              = job
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
      def run
        job.set_status("Starting")
        job.report_running

        assert_environment_exists

        chef_synchronize(chef_environment: environment_name, force: options[:force], job: job) do
          if component_versions.any?
            job.set_status("Setting component versions")
            set_component_versions(environment_name, plugin, component_versions)
          end

          if cookbook_versions.any?
            job.set_status("Setting cookbook versions")
            set_cookbook_versions(environment_name, cookbook_versions)
          end

          if environment_attributes.any?
            job.set_status("Setting environment attributes")
            set_environment_attributes(environment_name, environment_attributes)
          end

          if environment_attributes_file
            job.set_status("Setting environment attributes from #{environment_attributes_file}")
            set_environment_attributes_from_file(environment_name, environment_attributes_file)
          end

          run_chef if nodes.any?
        end

        job.report_success
      rescue => ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
      end

      private

        # @raise [EnvironmentNotFound]
        def assert_environment_exists
          unless chef_connection.environment.find(environment_name)
            raise EnvironmentNotFound.new(environment_name)
          end
        end

        # @return [Hash]
        def component_versions
          options[:component_versions] || {}
        end

        # @return [Hash]
        def cookbook_versions
          options[:cookbook_versions] || plugin.cookbook_versions
        end

        # @return [Hash]
        def environment_attributes
          options[:environment_attributes] || {}
        end

        # @return [String, nil]
        def environment_attributes_file
          options[:environment_attributes_file]
        end

        def max_concurrency
          options[:concurrency]
        end

        def upgrade_in_stack_order?
          options[:stack_order] == true
        end

        # @return [Array<String>]
        def nodes
          @nodes ||= begin
            job.set_status("Looking for nodes")

            nodes = plugin.nodes(environment_name)
            nodes.each do |component_name, group|
              group.each do |group_name, nodes|
                group[group_name] = nodes.map(&:public_hostname)
              end
            end

            log.info("Found nodes #{nodes.inspect}")
            nodes = bucket(nodes)
            nodes = slice_for_concurrency(nodes)

            log.info("Sliced nodes into concurrency buckets #{nodes.inspect}")

            unless nodes.any?
              log.info "No nodes in environment '#{environment_name}'"
            end

            nodes
          end
        end

        # Places hosts into buckets. The buckets depend on whether the
        # stack_order option is true. If it is true then the plugin
        # is consulted to obtain the stack_order tasks and a bucket is
        # created for each group in the bootstrap order. If the stack_order
        # option is not true then one bucket will be created with all the
        # nodes. If more than one group specifies the same host the duplicates
        # will be removed. If the stack_order is true and more than one group
        # specifies the same host it will appear in the bucket for the
        # first group it is found in and will be removed from all others.
        #
        # @example
        #   stack_order do
        #     bootstrap('some_component::db')
        #     bootstrap('some_component::app')
        #   end
        #
        #   And given:
        #   {
        #     some_component => {
        #       db => ['db1', 'db2', 'db3'],
        #       app => ['app1', 'app2', 'app3']
        #     }
        #   }
        #
        #  Then with stack_order == true
        #
        #    [['db1', 'db2', 'db3'],['app1','app2','app3']]
        #
        #  With stack_order == false
        #
        #    [['db1', 'db2', 'db3', 'app1','app2','app3']]
        #
        def bucket(nodes)
          if upgrade_in_stack_order?
            task_queue = plugin.bootstrap_routine.task_queue

            seen = []
            task_queue.collect do |task|
              component_name, group_name = task.group_name.split('::')
              group_nodes = nodes[component_name][group_name]
              group_nodes = group_nodes - seen
              seen += group_nodes
              group_nodes
            end
          else
            [] << nodes.collect do |component, groups|
              groups.collect do |group, nodes|
                nodes
              end
            end.flatten.compact.uniq
          end
        end

        # Takes an array of buckets and slices the buckets based on the
        # value of max_concurrency.
        #
        # @example
        #
        #   With a max_concurrency of two and an input of
        #     [['db1', 'db2', 'db3'],['app1','app2','app3']]
        #
        #   Returns
        #     [['db1', 'db2'], ['db3'], ['app1','app2'], ['app3']]
        def slice_for_concurrency(nodes)
          if max_concurrency
            nodes.inject([]) { |buckets, g| buckets += g.each_slice(max_concurrency).to_a }
          else
            nodes
          end
        end

        def run_chef
          log.info "Running Chef on #{nodes}"
          job.set_status("Running Chef on nodes")

          nodes.map do |group|
            log.info("Running chef concurrently on nodes #{group.inspect}")
            group.concurrent_map do |node|
              node_querier.chef_run(node)
            end
          end
        end
    end
  end
end
