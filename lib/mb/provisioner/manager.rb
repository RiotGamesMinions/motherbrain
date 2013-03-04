module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Handles provisioning of nodes and joining them to a Chef Server. Requests are
    # delegated to a provisioner of the desired type or 'Environment Factory' by
    # default.
    #
    class Manager
      class << self
        # @raise [Celluloid::DeadActorError] if Provisioner Manager has not been started
        #
        # @return [Celluloid::Actor(Provisioner::Manager)]
        def instance
          MB::Application[:provisioner_manager] or raise Celluloid::DeadActorError, "provisioner manager not running"
        end

        # Returns a provisioner for the given ID. The default provisioner will be returned
        # if nil is provided
        #
        # @param [#to_sym, nil] id
        #
        # @raise [ProvisionerNotRegistered] if no provisioner is registered with the given ID
        #
        # @return [Class]
        def choose_provisioner(id)
          id.nil? ? Provisioners.default : Provisioners.get!(id)
        end

        # Instantiate a new provisioner based on the given options
        #
        # @param [Hash] options
        #   see {choose_provisioner} and the initializer provisioner you are attempting to
        #   initialize
        #
        # @return [~Provisioner]
        def new_provisioner(options)
          choose_provisioner(options[:with]).new(options.except(:with))
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

      def initialize
        log.info { "Provision Manager starting..." }
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

      # Destroy an environment provisioned by MotherBrain
      #
      # @param [#to_s] environment
      #   name of the environment to destroy
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [JobTicket]
      def destroy(environment, options = {})
        job         = Job.new(:destroy_provision)
        ticket      = job.ticket
        provisioner = self.class.new_provisioner(options)

        provisioner.async.down(job, environment.to_s)

        ticket
      end

      def finalize
        log.info { "Provision Manager stopping..." }
      end

      # Create a new environment
      #
      # @param [MB::Job] job
      # @param [#to_s] environment
      #   name of the environment to create or append to
      # @param [MB::Provisioner::Manifest] manifest
      #   manifest of nodes to create
      # @param [MB::Plugin] plugin
      #   the plugin we are creating these nodes for
      #
      # @option options [Hash] :component_versions (Hash.new)
      #   Hash of components and the versions to set them to
      # @option options [Hash] :cookbook_versions (Hash.new)
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] :environment_attributes (Hash.new)
      #   Hash of additional attributes to set on the environment
      # @option options [Boolean] :skip_bootstrap (false)
      #   skip automatic bootstrapping of the created environment
      # @option options [#to_sym] :with
      #   id of provisioner to use
      # @option options [Boolean] :force (false)
      #   force provisioning nodes to the environment even if the environment is locked
      def provision(job, environment, manifest, plugin, options = {})
        options = options.reverse_merge(
          component_versions: Hash.new,
          cookbook_versions: Hash.new,
          environment_attributes: Hash.new,
          skip_bootstrap: false,
          force: false
        )

        job.report_running("preparing to provision")

        worker = self.class.new_provisioner(options)
        Provisioner::Manifest.validate!(manifest, plugin)
        
        response = worker.up(job, environment, manifest, plugin, options.slice(*WORKER_OPTS))

        if options[:skip_bootstrap]
          job.report_success(response)
        else
          bootstrap_manifest = Bootstrap::Manifest.from_provisioner(response, manifest)
          bootstrapper.bootstrap(job, environment, bootstrap_manifest, plugin, options)
        end
      rescue InvalidProvisionManifest, UnexpectedProvisionCount, EF::REST::Error => ex
        log.fatal { "an error occured: #{ex}" }
        job.report_failure(ex)
      rescue => ex
        log.fatal { "unknown error occured: #{ex}"}
        job.report_failure("internal error")
      ensure
        job.finalize if job && job.alive?
      end
    end
  end
end
