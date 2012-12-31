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
      # @option options [MB::Job] :job
      # @option options [Boolean] :force
      #   ignore and bypass any existing locks on an environment
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) [10.0] timeout value for SSH bootstrap
      #   * :sudo (Boolean) [True] bootstrap with sudo
      # @option options [String] :server_url
      #   URL to the Chef API to bootstrap the target node(s) to
      # @option options [String] :client_name
      #   name of the client used to authenticate with the Chef API
      # @option options [String] :client_key
      #   filepath to the client's private key used to authenticate with the Chef API
      # @option options [String] :organization
      #   the Organization to connect to. This is only used if you are connecting to
      #   private Chef or hosted Chef
      # @option options [String] :validator_client
      #   the name of the Chef validator client to use in bootstrapping
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node
      # @option options [String] :encrypted_data_bag_secret_path
      #   filepath on your host machine to your organizations encrypted data bag secret
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
          force: false,
          job: Job.new(:bootstrap)
        )
        options[:environment] = environment
        job = options[:job]

        async.start(environment, manifest, plugin, job, options)

        job.ticket
      end

      # @param [String] environment
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Plugin] plugin
      #   a MotherBrain plugin with a bootstrap routine to follow
      # @param [MotherBrain::Job] job
      #
      # @see #bootstrap for options
      def start(environment, manifest, plugin, job, options = {})
        job.report_running

        manifest.validate!(plugin)

        task_queue = plugin.bootstrap_routine.task_queue.dup

        unless Application.ridley.environment.find(environment)
          raise EnvironmentNotFound, "Environment: '#{environment}' not found on '#{Application.ridley.server_url}'"
        end

        log.info { "Starting bootstrap of nodes on: #{environment}" }
        sequential_bootstrap(environment, manifest, task_queue, job, options)
      rescue => error
        log.fatal { "unknown error occured: #{error}"}
        job.report_failure(error)
      end

      def finalize
        log.info { "Bootstrap Manager stopping..." }
      end

      # @param [String] environment
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Array<Bootstrap::BootTask>] task_queue
      #   a MotherBrain plugin with a bootstrap routine to follow
      # @param [MotherBrain::Job] job
      #
      # @see #bootstrap for options
      def sequential_bootstrap(environment, manifest, task_queue, job, options = {})
        chef_synchronize(chef_environment: environment, force: options[:force], job: job) do
          while tasks = task_queue.shift
            job.status = "Bootstrapping #{Array(tasks).collect(&:id).join(', ')}"

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
      #
      # @see #bootstrap for options
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
