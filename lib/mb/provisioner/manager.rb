module MotherBrain
  class ProvisionerSupervisor < Celluloid::SupervisionGroup; end

  module Provisioner
    # Handles provisioning of nodes and joining them to a Chef Server. Requests are
    # delegated to a provisioner of the desired type or 'Environment Factory' by
    # default.
    class Manager
      class << self
        # @raise [Celluloid::DeadActorError] if Provisioner Manager has not been started
        #
        # @return [Celluloid::Actor(Provisioner::Manager)]
        def instance
          MB::Application[:provisioner_manager] or raise Celluloid::DeadActorError, "provisioner manager not running"
        end
      end

      WORKER_OPTS = [
        :component_versions,
        :cookbook_versions,
        :environment_attributes,
        :environment_attributes_file,
        :skip_bootstrap,
        :force
      ]

      include Celluloid
      include MB::Logging
      include MB::Mixin::Services

      finalizer :finalize_callback

      attr_reader :provisioner_registry

      def initialize
        log.info { "Provision Manager starting..." }
        @provisioner_registry   = Celluloid::Registry.new
        @provisioner_supervisor = ProvisionerSupervisor.new_link(@provisioner_registry)
        Provisioner.all.each do |provisioner|
          @provisioner_supervisor.supervise_as(provisioner.provisioner_id, provisioner)
        end
      end

      # Asynchronously destroy an environment that was created with motherbrain
      #
      # @param [String] environment
      #   name of the environment to destroy
      #
      # @option options [#to_sym] :with
      #   id of provisioner to use
      def async_destroy(environment, options = {})
        job = Job.new(:destroy_provision)
        async(:destroy, job, environment, options)

        job.ticket
      end

      # Asynchronously create a new environment
      #
      # @param [#to_s] environment
      #   name of the environment to create or append to
      # @param [MB::Provisioner::Manifest] manifest
      #   manifest of nodes to create
      # @param [MB::Plugin] plugin
      #   the plugin we are creating these nodes for
      #
      # @see {#provision} for options
      #
      # @return [MB::JobRecord]
      #   a reference to the executing job
      def async_provision(environment, manifest, plugin, options = {})
        options = options.reverse_merge(skip_bootstrap: false)

        job_type = options[:skip_bootstrap] ? :provision : :provision_and_bootstrap
        job      = Job.new(job_type)

        async(:provision, job, environment, manifest, plugin, options)

        job.ticket
      end

      # Retrieve the running provisioner for the given ID. The default provisioner will be returned
      # if nil is provided.
      #
      # @param [#to_sym, nil] id ({Provisioner.default_id})
      #
      # @raise [ProvisionerNotStarted]
      #   if no provisioner is registered with the given ID
      #
      # @return [MB::Provisioner::Base]
      def choose_provisioner(id)
        id ||= Provisioner.default_id

        unless provisioner = @provisioner_registry[id.to_sym]
          abort ProvisionerNotStarted.new(id)
        end

        provisioner
      end

      # Destroy an environment that was created with motherbrain
      #
      # @param [MB::Job] job
      #   a job to update with progress
      # @param [String] environment
      #   name of the environment to destroy
      #
      # @option options [#to_sym] :with
      #   id of provisioner to use
      def destroy(job, environment, options = {})
        job.report_running

        worker = choose_provisioner(options.delete(:with))
        worker.down(job, environment)

        job.report_success("environment destroyed")
      rescue => ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
      end

      # Create a new environment
      #
      # @param [MB::Job] job
      #   a job to update with progress
      # @param [String] environment
      #   name of the environment to create or append to
      # @param [MB::Provisioner::Manifest] manifest
      #   manifest of nodes to create
      # @param [MB::Plugin] plugin
      #   the plugin we are creating these nodes for
      #
      # @option options [String] :chef_version
      #   version of Chef to install on the node
      # @option options [Hash] :component_versions (Hash.new)
      #   Hash of components and the versions to set them to
      # @option options [Hash] :cookbook_versions (Hash.new)
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] :environment_attributes (Hash.new)
      #   Hash of additional attributes to set on the environment
      # @option options [Boolean] :skip_bootstrap (false)
      #   skip automatic bootstrapping of the created environment
      # @option options [Boolean] :force (false)
      #   force provisioning nodes to the environment even if the environment is locked
      def provision(job, environment, manifest, plugin, options = {})
        job.report_running("preparing to provision")

        options = options.reverse_merge(
          component_versions: Hash.new,
          cookbook_versions: Hash.new,
          environment_attributes: Hash.new,
          skip_bootstrap: false,
          force: false
        )

        manifest.validate!(plugin)
        response = choose_provisioner(manifest.provisioner).up(job, environment, manifest, plugin, options)

        unless options[:skip_bootstrap]
          bootstrap_manifest = Bootstrap::Manifest.from_provisioner(response, manifest)
          write_bootstrap_manifest(job, environment, bootstrap_manifest, plugin)
          bootstrapper.bootstrap(job, environment, bootstrap_manifest, plugin, options)
        end

        job.report_success unless job.completed?
      rescue => ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
      end

      private

        # @param [MB::Job] job
        # @param [String] environment
        # @param [MB::Manifest] manifest
        # @param [MB::Plugin] plugin
        def write_bootstrap_manifest(job, environment, manifest, plugin)
          filename = "#{plugin.name}_#{environment}_#{Time.now.to_i}.json"
          path     = MB::FileSystem.manifests.join(filename)
          contents = JSON.pretty_generate(manifest.as_json)

          job.set_status("Writing bootstrap manifest to #{path}")

          File.open(path, 'w') { |file| file.write contents }
        end

        def finalize_callback
          log.info { "Bootstrap Manager stopping..." }
          @provisioner_supervisor.terminate
        end
    end
  end
end
