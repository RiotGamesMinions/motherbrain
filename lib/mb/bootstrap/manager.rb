module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      class << self
        # @raise [Celluloid::DeadActorError] if Bootstrap Manager has not been started
        #
        # @return [Celluloid::Actor(Bootstrap::Manager)]
        def instance
          MB::Application[:bootstrap_manager] or raise Celluloid::DeadActorError, "bootstrap manager not running"
        end
      end

      include Celluloid
      include MB::Logging
      include MB::Mixin::Locks
      include MB::Mixin::AttributeSetting

      def initialize
        log.info { "Bootstrap Manager starting..." }
      end

      # Asynchronously bootstrap a collection of nodes described in the given manifest in the proper order
      #
      # @param [String] environment
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Plugin] plugin
      #   a MotherBrain plugin with a bootstrap routine to follow
      #
      # @option options [Hash] :component_versions (Hash.new)
      #   Hash of components and the versions to set them to
      # @option options [Hash] :cookbook_versions (Hash.new)
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] :environment_attributes (Hash.new)
      #   Hash of additional attributes to set on the environment
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
      #
      # @return [MB::JobRecord]
      #   a reference to the executing job
      def async_bootstrap(environment, manifest, plugin, options = {})
        job = Job.new(:bootstrap)
        async(:bootstrap, job, environment, manifest, plugin, options)

        job.ticket
      end

      # Bootstrap a collection of nodes described in the given manifest in the proper order
      #
      # @param [MB::Job] job
      # @param [String] environment
      # @param [MB::Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [MB::Plugin] plugin
      #   a MotherBrain plugin with a bootstrap routine to follow
      #
      # @see {#bootstrap} for options
      def bootstrap(job, environment, manifest, plugin, options = {})
        options = options.reverse_merge(
          cookbook_versions: Hash.new,
          component_versions: Hash.new,
          environment_attributes: Hash.new,
          hints: Hash.new,
          bootstrap_proxy: Application.config[:chef][:bootstrap_proxy],
          force: false
        )

        job.report_running

        manifest.validate!(plugin)

        job.status = "searching for environment"
        unless chef_conn.environment.find(environment)
          log.fatal { "Failed to location the environment '#{environment}'"}
          return job.report_failure("Environment '#{environment}' not found")
        end

        job.status = "Starting bootstrap of nodes on: #{environment}"
        task_queue = plugin.bootstrap_routine.task_queue.dup
        
        chef_synchronize(chef_environment: environment, force: options[:force], job: job) do
          if options[:component_versions].any?
            job.status = "Setting component versions"
            set_component_versions(environment, plugin, options[:component_versions])
          end

          if options[:cookbook_versions].any?
            job.status = "Setting cookbook versions"
            set_cookbook_versions(environment, options[:cookbook_versions])
          end

          if options[:environment_attributes].any?
            job.status = "Setting environment attributes"
            set_environment_attributes(environment, options[:environment_attributes])
          end

          unless options[:environment_attributes_file].nil?
            job.status = "Setting environment attributes from file"
            begin
              attribute_hash = MultiJson.decode(File.open(options[:environment_attributes_file]).read)
              set_environment_attributes_from_hash(environment, attribute_hash)
            rescue MultiJson::DecodeError => error
              log.fatal { "Failed to parse json supplied in environment attributes file."}
              return job.report_failure(error)
            end
          end

          while tasks = task_queue.shift
            job.status = "bootstrapping group(s): #{Array(tasks).collect(&:groups).flatten.uniq.join(', ')}"

            failures = concurrent_bootstrap(manifest, tasks, options).select do |group, response_set|
              response_set.has_errors?
            end

            unless failures.empty?
              job.report_failure("failed to bootstrap group(s): #{failures.keys.join(', ')}")
            end
          end

          job.report_success
        end
      rescue => error
        log.fatal { "unknown error occured: #{error}"}
        job.report_failure(error)
      end

      def finalize
        log.info { "Bootstrap Manager stopping..." }
      end

      private

        def chef_conn
          Application.ridley
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
            nodes = manifest.hosts_for_groups(boot_task.groups)

            worker_options = options.merge(
              run_list: boot_task.group_object.run_list,
              attributes: boot_task.group_object.chef_attributes
            )

            Worker.new(boot_task.groups, nodes, worker_options)
          end

          futures = workers.collect do |worker|
            [
              worker.group_ids,
              worker.future.run
            ]
          end

          {}.tap do |response|
            futures.each do |group_ids, future|
              response[group_ids] = future.value
            end
          end
        ensure
          Array(workers).map { |worker| worker.terminate if worker.alive? }
        end
    end
  end
end
