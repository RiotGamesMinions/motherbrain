module MotherBrain
  module Bootstrap
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

      finalizer :finalize_callback

      def initialize
        log.debug { "Bootstrap Manager starting..." }
        @worker_pool = Bootstrap::Worker.pool(size: 50)
      end

      # Asynchronously bootstrap a collection of nodes described in the given manifest in the proper order
      #
      # @param [String] environment
      #   name of the environment to bootstrap nodes to
      # @param [Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [Plugin] plugin
      #   a motherbrain plugin with a bootstrap routine to follow
      #
      # @option options [Hash] :component_versions (Hash.new)
      #   Hash of components and the versions to set them to
      # @option options [Hash] :cookbook_versions (Hash.new)
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] :environment_attributes (Hash.new)
      #   Hash of additional attributes to set on the environment
      # @option options [Boolean] :force
      #   ignore and bypass any existing locks on an environment
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of node level attributes to set on the bootstrapped nodes
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
      # @option options [String] :chef_version
      #   version of Chef to install on the node
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
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
      #   a job to send progress updates to
      # @param [String] environment
      #   name of the environment to bootstrap nodes to
      # @param [MB::Bootstrap::Manifest] manifest
      #   manifest of nodes and what they should become
      # @param [MB::Plugin] plugin
      #   a motherbrain plugin with a bootstrap routine to follow
      #
      # @see {#async_bootstrap} for options
      def bootstrap(job, environment, manifest, plugin, options = {})
        options = options.reverse_merge(
          component_versions: Hash.new,
          environment_attributes: Hash.new,
          hints: Hash.new,
          bootstrap_proxy: Application.config[:chef][:bootstrap_proxy],
          sudo: Application.config[:ssh][:sudo],
          force: false
        )
        options[:environment] = environment

        job.report_running

        validate_bootstrap_configuration!(manifest, plugin)

        job.set_status("Searching for environment")
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

          cookbook_versions = options[:cookbook_versions] || plugin.cookbook_versions
          if cookbook_versions.any?
            job.set_status("Setting cookbook versions")
            set_cookbook_versions(environment, cookbook_versions)
          end

          if options[:environment_attributes].any?
            job.set_status("Setting environment attributes")
            set_environment_attributes(environment, options[:environment_attributes])
          end

          unless options[:environment_attributes_file].nil?
            job.set_status("Setting environment attributes from file")
            set_environment_attributes_from_file(environment, options[:environment_attributes_file])
          end

          while tasks = task_queue.shift
            host_errors = Hash.new
            group_names = Array(tasks).collect(&:group_name).join(', ')

            instructions = Bootstrap::Routine.map_instructions(tasks, manifest)
            if instructions.empty?
              log.info "Skipping bootstrap of group(s): #{group_names}. No hosts defined in manifest to bootstrap for " +
              "these groups."
              next
            end

            job.set_status("Bootstrapping group(s): #{group_names}")

            concurrent_bootstrap(job, manifest, instructions, options).each do |host, host_info|
              if host_info[:result][:status] == :error
                host_errors[host] = host_info
              end
            end

            unless host_errors.empty?
              abort GroupBootstrapError.new(host_errors)
            end

            job.set_status("Finished bootstrapping group(s): #{group_names}")
          end
        end

        job.report_success
      rescue => ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
      end

      # Concurrently bootstrap a grouped collection of nodes from a manifest and return
      # their results. This function will block until all nodes have finished
      # bootstrapping.
      #
      # @param [MB::Job] job
      #   a job to send progress updates to
      # @param [Bootstrap::Manifest] manifest
      #   a hash where the keys are node group names and the values are arrays of hostnames
      # @param [Hash] instructions
      #   a hash containing an entry for every host to bootstrap and the groups it belongs to, the
      #   run list it should be bootstrapped with, and the chef attributes to be applied to the node
      #   for it's first run.
      #
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to use in the first Chef run
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
      # @option options [String] :chef_version
      #   version of Chef to install on the node
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      #
      # @return [Hash]
      #   a hash where keys are group names and their values are the results of {Bootstrap::Worker#run}
      #
      # @example
      #   {
      #     "cloud-1.riotgames.com" => {
      #       groups: ["proxy_server::default", "app_server::default"],
      #       result: {
      #         status: :ok,
      #         message: "",
      #         bootstrap_type: :full
      #       }
      #     },
      #     "cloud-2.riotgames.com" => {
      #       groups: ["database_master::default"],
      #       result: {
      #         status: :error,
      #         message: "client verification error"
      #         bootstrap_type: :partial
      #       }
      #     },
      #     "cloud-3.riotgames.com" => {
      #       groups: ["database_slave::default"],
      #       result: {
      #         status: :ok
      #         message: ""
      #         bootstrap_type: :partial
      #       }
      #     }
      #   }
      def concurrent_bootstrap(job, manifest, instructions, options = {})
        response     = Hash.new

        instructions.each do |host, host_info|
          boot_options = options.merge(host_info[:options])
          boot_options.merge!(manifest[:options]) if manifest[:options]

          job.set_status("Bootstrapping #{host} with group(s): #{host_info[:groups]}")

          response[host] = {
            groups: host_info[:groups],
            result: worker_pool.future(:run, host, boot_options)
          }
        end

        response.each { |host, host_info| host_info[:result] = host_info[:result].value }
      end

      private

        attr_reader :worker_pool

        def finalize_callback
          log.debug { "Bootstrap Manager stopping..." }
          worker_pool.terminate if worker_pool && worker_pool.alive?
        end

        def validate_bootstrap_configuration!(manifest, plugin)
          manifest.validate!(plugin)

          validator_path = File.expand_path(config_manager.config.chef[:validator_path])

          unless File.exists?(validator_path)
            raise ValidatorPemNotFound.new(validator_path)
          end
        end
    end
  end
end
