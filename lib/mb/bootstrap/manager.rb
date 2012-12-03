module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      class << self
        # @param [Hash] options (Hash.new)
        #
        # @raise [ArgumentError]
        def validate_options(options = {})
          missing = (REQUIRED_OPTS - options.keys)

          unless missing.empty?
            missing.collect! { |opt| "'#{opt}'" }
            raise ArgumentError, "Missing required option(s): #{missing.join(', ')}"
          end

          unless options.keys.include?(:ssh_keys) || options.keys.include?(:ssh_password)
            raise ArgumentError, "Missing required option(s): ':ssh_keys' or ':ssh_password' must be specified"
          end
        end
      end

      include Celluloid
      include ActorUtil

      # Required options for {#bootstrap}
      REQUIRED_OPTS = [
        :server_url,
        :client_name,
        :client_key,
        :validator_client,
        :validator_path,
        :ssh_user
      ].freeze

      # Options given to {#bootstrap} to be passed to Ridley
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

      # Bootstrap a collection of nodes described in the given manifest by performing
      # each {BootTask} in the proper order
      #
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Bootstrap::Routine] routine
      #   routine to follow for the bootstrap process
      # @option options [String] :server_url
      #   URL to the Chef API to bootstrap the target node(s) to (required)
      # @option options [String] :client_name
      #   name of the client used to authenticate with the Chef API (required)
      # @option options [String] :client_key
      #   filepath to the client's private key used to authenticate with the Chef API (requirec)
      # @option options [String] :organization
      #   the Organization to connect to. This is only used if you are connecting to
      #   private Chef or hosted Chef
      # @option options [String] :validator_client
      #   the name of the Chef validator client to use in bootstrapping (requirec)
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node (required)
      # @option options [String] :encrypted_data_bag_secret_path (nil)
      #   filepath on your host machine to your organizations encrypted data bag secret
      # @option options [String] :ssh_user
      #   a shell user that will login to each node and perform the bootstrap command on (requirec)
      # @option options [String] :ssh_password
      #   the password for the shell user that will perform the bootstrap"
      # @option options [Array<String>, String] :ssh_keys
      #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
      # @option options [String] :environment ('_default')
      # @option options [Float] :ssh_timeout (1.5)
      #   timeout value for SSH bootstrap
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      #
      # @raise [InvalidBootstrapManifest] if the given manifest does not pass validation
      # @raise [ArgumentError] if a required option is not given
      #
      # @return [Array<Hash>]
      #   an array containing hashes from each item in the task_queue. The hashes contain
      #   keys for bootstrapped node groups and values that are the Ridley::SSH::ResultSet
      #   which contains the result of bootstrapping each node.
      #
      # @example
      #   bootstrap(manifest, routine, options) => [
      #     {
      #       instance_type: "m1.large",
      #       public_hostname: "euca-10-20-37-146.eucalyptus.cloud.riotgames.com"
      #     },
      #     {
      #       instance_type: "m1.large",
      #       public_hostname: "euca-10-20-37-134.eucalyptus.cloud.riotgames.com"
      #     }
      #   ]
      #
      def bootstrap(manifest, routine, options = {})
        defer {
          self.class.validate_options(options)
          manifest.validate!(routine)

          responses  = Array.new
          task_queue = routine.task_queue.dup
          chef_conn  = Ridley::Connection.new(options.slice(*RIDLEY_OPT_KEYS))

          until task_queue.empty?
            responses.push concurrent_bootstrap(chef_conn, manifest, task_queue.shift, options.except(*RIDLEY_OPT_KEYS))
          end

          responses
        }
      end

      private

        # Concurrently bootstrap a grouped collection of nodes from a manifest and return
        # their results. This function will block until all nodes have finished
        # bootstrapping.
        #
        # @param [Ridley::Connection] chef_conn
        #   connection for Chef
        # @param [Bootstrap::Manifest] manifest
        #   a hash where the keys are node group names and the values are arrays of hostnames
        # @param [BootTask, Array<BootTask>] boot_tasks
        #   a hash where the keys are node group names and the values are arrays of hostnames
        # @option options [String] :environment ('_default')
        # @option options [Hash] :hints (Hash.new)
        #   a hash of Ohai hints to place on the bootstrapped node
        # @option options [Boolean] :sudo (true)
        #   bootstrap with sudo
        # @option options [String] :template ("omnibus")
        #   bootstrap template to use
        # @option options [String] :bootstrap_proxy (nil)
        #   URL to a proxy server to bootstrap through
        #
        # @return [Hash]
        #   a hash where keys are group names and their values are their Ridley::SSH::ResultSet
        def concurrent_bootstrap(chef_conn, manifest, boot_tasks, options = {})
          workers = Array.new
          workers = Array(boot_tasks).collect do |boot_task|
            nodes = manifest[boot_task.id]
            worker_options = options.merge(
              run_list: boot_task.group.run_list,
              attributes: boot_task.group.chef_attributes
            )
            
            Worker.new(boot_task.id, nodes, chef_conn, worker_options)
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
          workers.map(&:terminate) if workers
        end
    end
  end
end
