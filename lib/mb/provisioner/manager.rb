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
        :skip_bootstrap
      ]

      include Celluloid
      include MB::Logging

      def initialize
        log.info { "Provision Manager starting..." }
      end

      # Returns a SafeReturn array whose body is an array of hashes representing the nodes
      # created for the given manifest
      #
      # @example body of success
      #   [
      #     {
      #       instance_type: "m1.large",
      #       public_hostname: "node1.riotgames.com"
      #     },
      #     {
      #       instance_type: "m1.small",
      #       public_hostname: "node2.riotgames.com"
      #     }
      #   ]
      #
      # @param [#to_s] environment
      #   name of the environment to create or append to
      # @param [Provisioner::Manifest] manifest
      #   manifest of nodes to create
      # @param [MotherBrain::Plugin] plugin
      #   the plugin we are creating these nodes for
      #
      # @option options [Boolean] :skip_bootstrap
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [JobTicket]
      def provision(environment, manifest, plugin, options = {})
        job_type    = options[:skip_bootstrap] ? :provision : :provision_and_bootstrap
        job         = Job.new(job_type)
        ticket      = job.ticket
        provisioner = self.class.new_provisioner(options)
        Provisioner::Manifest.validate!(manifest, plugin)

        log.debug "manager delegating creation of #{environment}..."
        provisioner.async.up(job, environment, manifest, plugin, options.slice(*WORKER_OPTS))

        ticket
      rescue InvalidProvisionManifest => e
        job.report_failure(e)
        ticket
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

        log.debug "manager delegating destruction of #{environment}..."
        provisioner.async.down(job, environment.to_s)

        ticket
      end

      def finalize
        log.info { "Provision Manager stopping..." }
      end
    end
  end
end
