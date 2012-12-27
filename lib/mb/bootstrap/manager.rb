module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      class << self
        # @raise [Celluloid::DeadActorError] if Bootstrap Manager has not been started
        #
        # @return [Celluloid::Actor(Bootstrap::Manager)]
        def instance
          Celluloid::Actor[:bootstrap_manager] or raise Celluloid::DeadActorError, "bootstrap manager not running"
        end
      end

      include Celluloid
      include MB::Logging
      include MB::Locks

      # Required options for {#bootstrap}
      REQUIRED_OPTS = [
        :server_url,
        :client_name,
        :client_key,
        :validator_client,
        :validator_path,
        :ssh
      ].freeze

      def initialize
        log.info { "Bootstrap Manager starting..." }
      end

      # Bootstrap a collection of nodes described in the given manifest by performing
      # each {BootTask} in the proper order
      #
      # @param [String] environment
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Plugin] plugin
      #   a MotherBrain plugin with a bootstrap routine to follow
      #
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      def bootstrap(environment, manifest, plugin, options = {})
        options = options.reverse_merge(
          hints: Hash.new,
          bootstrap_proxy: Application.config[:chef][:bootstrap_proxy],
          force: false
        )
        options[:environment] = environment

        job = Job.new(:bootstrap)

        async.start(environment, manifest, plugin, job, options)

        job.ticket
      end

      # @see #bootstrap
      #
      # @param [MotherBrain::Job] job
      def start(environment, manifest, plugin, job, options = {})
        job.report_running

        manifest.validate!(plugin)

        task_queue = plugin.bootstrap_routine.task_queue.dup

        unless Application.ridley.environment.find(environment)
          raise EnvironmentNotFound, "Environment: '#{environment}' not found on '#{Application.ridley.server_url}'"
        end

        log.info { "Starting bootstrap of nodes on: #{environment}" }
        async.sequential_bootstrap(environment, manifest, task_queue, job, options)
      rescue => error
        log.fatal { "unknown error occured: #{error}"}
        job.report_failure(error)
      end

      def finalize
        log.info { "Bootstrap Manager stopping..." }
      end

      # @see #bootstrap
      #
      # @param [MotherBrain::Job] job
      def sequential_bootstrap(environment, manifest, task_queue, job, options = {})
        chef_synchronize(chef_environment: environment, force: options[:force], job: job) do
          while tasks = task_queue.shift
            job.status = "Bootstrapping #{tasks.collect(&:id).join(', ')}"

            concurrent_bootstrap(manifest, tasks, options)
          end
        end

        job.report_success
      rescue => error
        log.fatal { "unknown error occured: #{error}"}
        job.report_failure(error)
      end

      # Concurrently bootstrap a grouped collection of nodes from a manifest and return
      # their results. This function will block until all nodes have finished
      # bootstrapping.
      #
      # @param [Bootstrap::Manifest] manifest
      #   a hash where the keys are node group names and the values are arrays of hostnames
      # @param [BootTask, Array<BootTask>] boot_tasks
      #   a hash where the keys are node group names and the values are arrays of hostnames
      # @option options [String] :environment ('_default')
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      #
      # @return [Hash]
      #   a hash where keys are group names and their values are their Ridley::SSH::ResultSet
      def concurrent_bootstrap(manifest, boot_tasks, options = {})
        workers = Array(boot_tasks).collect do |boot_task|
          nodes = manifest[boot_task.id]

          worker_options = options.merge(
            run_list: boot_task.group.run_list,
            attributes: boot_task.group.chef_attributes
          )

          Worker.new(boot_task.id, nodes, worker_options)
        end

        futures = workers.collect do |worker|
          [
            worker.group_id,
            worker.future.run
          ]
        end

        {}.tap do |response|
          futures.each do |group_id, future|
            response[group_id] = future.value
          end
        end
      ensure
        workers.map { |worker| worker.terminate if worker.alive? }
      end
    end
  end
end
