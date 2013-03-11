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
      include MB::Mixin::Services

      finalizer do
        log.info { "Bootstrap Manager stopping..." }
      end

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
          environment: environment,
          cookbook_versions: Hash.new,
          component_versions: Hash.new,
          environment_attributes: Hash.new,
          hints: Hash.new,
          bootstrap_proxy: Application.config[:chef][:bootstrap_proxy],
          force: false
        )

        job.report_running

        manifest.validate!(plugin)

        job.set_status("searching for environment")
        unless chef_connection.environment.find(environment)
          return job.report_failure("Environment '#{environment}' not found")
        end

        job.set_status("Starting bootstrap of nodes on: #{environment}")
        task_queue = plugin.bootstrap_routine.task_queue.dup
        
        chef_synchronize(chef_environment: environment, force: options[:force], job: job) do
          if options[:component_versions].any?
            job.set_status("Setting component versions")
            set_component_versions(environment, plugin, options[:component_versions])
          end

          if options[:cookbook_versions].any?
            job.set_status("Setting cookbook versions")
            set_cookbook_versions(environment, options[:cookbook_versions])
          end

          if options[:environment_attributes].any?
            job.set_status("Setting environment attributes")
            set_environment_attributes(environment, options[:environment_attributes])
          end

          unless options[:environment_attributes_file].nil?
            job.set_status("Setting environment attributes from file")
            begin
              attribute_hash = MultiJson.decode(File.open(options[:environment_attributes_file]).read)
              set_environment_attributes_from_hash(environment, attribute_hash)
            rescue MultiJson::DecodeError => ex
              abort InvalidAttributesFile.new(ex.to_s)
            end
          end

          while tasks = task_queue.shift
            grouped_errors = Hash.new
            group_names    = "#{Array(tasks).collect(&:groups).flatten.uniq.join(', ')}"

            job.set_status("bootstrapping group(s): #{group_names}")
            concurrent_bootstrap(job, manifest, tasks, options).each do |group, responses|
              errors = responses.select { |response| response[:status] == :error }

              unless errors.empty?
                grouped_errors[group] ||= Array.new
                grouped_errors[group] << errors
              end
            end

            unless grouped_errors.empty?
              abort GroupBootstrapError.new(grouped_errors)
            end

            job.set_status("done bootstrapping group(s): #{group_names}")
          end
        end

        job.report_success
      rescue ResourceLocked, BootstrapError => ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
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
      #   a hash where keys are group names and their values are the results of {Bootstrap::Worker#run}
      #
      # @example
      #   {
      #     "activemq::master" => [
      #       {
      #         node: "cloud-1.riotgames.com",
      #         status: :ok
      #         message: ""
      #         bootstrap_type: :full
      #       },
      #       {
      #         node: "cloud-2.riotgames.com",
      #         status: :error,
      #         message: "client verification error"
      #         bootstrap_type: :partial
      #       }
      #     ]
      #     "activemq::slave" => [
      #       {
      #         node: "cloud-3.riotgames.com",
      #         status: :ok
      #         message: ""
      #         bootstrap_type: :partial
      #       }
      #     ]
      #   }
      def concurrent_bootstrap(job, manifest, boot_tasks, options = {})
        workers  = Array.new
        response = Hash.new

        Array(boot_tasks).each do |boot_task|
          groups = boot_task.groups
          nodes  = manifest.hosts_for_groups(groups)

          if nodes.empty?
            log.info { "Skipping bootstrap of group(s): #{groups}. No hosts defined in manifest for these group(s)." }
            next
          end

          worker_options = options.merge(
            run_list: boot_task.group_object.run_list,
            attributes: boot_task.group_object.chef_attributes
          )

          workers << worker = Worker.new(nodes)

          job.set_status("performing bootstrap on group(s): #{groups}")
          response[groups] = worker.future(:run, worker_options)
        end

        response.each_with_object({}) do |(groups, future), resp|
          resp[groups] = future.value
        end
      ensure
        workers.map { |worker| worker.terminate if worker.alive? }
      end
    end
  end
end
