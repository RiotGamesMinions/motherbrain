module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      include Celluloid
      include ActorUtil

      # Bootstrap a collection of nodes described in the given manifest by performing
      # each {BootTask} in the proper order
      #
      # @param [Bootstrap::Manifest] manifest
      #   a hash where the keys are node group names and the values are arrays of hostnames
      # @param [Bootstrap::Routine] routine
      # @param [Hash] options
      #   options to pass to {#concurrent_bootstrap}
      #
      # @raise [InvalidBootstrapManifest] if the given manifest does not pass validation
      #
      # @return [Array<Hash>]
      #   an array containing hashes from each item in the task_queue. The hashes contain
      #   keys for bootstrapped node groups and values that are the Ridley::SSH::ResultSet
      #   which contains the result of bootstrapping each node.
      def bootstrap(manifest, routine, options = {})
        manifest.validate!(routine)

        responses = Array.new

        until routine.task_queue.empty?
          reduced_manifest = self.class.manifest_reduce(manifest, task_queue.shift)
          responses.push concurrent_bootstrap(reduced_manifest, plugin, options)
        end

        responses
      end

      # Concurrently bootstrap a grouped collection of nodes from a manifest and return
      # their results. This function will block until all nodes have finished
      # bootstrapping.
      #
      # @param [Bootstrap::Manifest] manifest
      #   a hash where the keys are node group names and the values are arrays of hostnames
      # @option options [String] :server_url
      #   URL to the Chef API to bootstrap the target node(s) to
      # @option options [String] :ssh_user
      #   a shell user that will login to each node and perform the bootstrap command on
      # @option options [String] :ssh_password
      #   the password for the shell user that will perform the bootstrap"
      # @option options [Array<String>, String] :ssh_keys
      #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
      # @option options [Float] :ssh_timeout
      #   timeout value for SSH bootstrap (default: 1.5)
      # @option options [String] :validator_client
      #   the name of the Chef validator client to use in bootstrapping
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node (required)
      # @option options [String] :bootstrap_proxy
      #   URL to a proxy server to bootstrap through (default: nil)
      # @option options [String] :encrypted_data_bag_secret_path
      #   filepath on your host machine to your organizations encrypted data bag secret (default: nil)
      # @option options [Hash] :hints
      #   a hash of Ohai hints to place on the bootstrapped node (default: Hash.new)
      # @option options [Boolean] :sudo
      #   bootstrap with sudo (default: true)
      # @option options [String] :template
      #   bootstrap template to use (default: omnibus)
      #
      # @return [Hash]
      #   a hash where keys are group names and their values are their Ridley::SSH::ResultSet
      def concurrent_bootstrap(manifest, plugin, options = {})
        workers = Array.new
        workers = manifest.collect do |group_id, nodes|
          component_name, group_name = group_id.split('::')
          group = plugin.component(component_name).group(group_name)

          worker_options = options.merge(run_list: group.run_list, attributes: group.chef_attributes)
          Worker.new(group_id, nodes, worker_options)
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
