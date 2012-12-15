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
          Celluloid::Actor[:provisioner_manager] or raise Celluloid::DeadActorError, "provisioner manager not running"
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
          id = options.delete(:with)
          choose_provisioner(id).new(options)
        end
      end

      include Celluloid
      include MB::Logging
      include MB::ActorUtil

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
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [MB::JobTicket]
      def provision(environment, manifest, plugin, options = {})
        job = Job.new(:provision)
        Provisioner::Manifest.validate(manifest, plugin)

        provisioner = self.class.new_provisioner(options)
        provisioner.async.up(job.freeze, environment.to_s, manifest)
        job.ticket
      rescue InvalidProvisionManifest => e
        job.transition(Job::Status::FAILURE, e)
        job.ticket
      ensure
        provisioner.terminate if provisioner && provisioner.alive?
      end

      # @param [#to_s] environment
      #   name of the environment to destroy
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [MB::JobTicket]
      def destroy(environment, options = {})
        job = Job.new(:destroy_provision)
        provisioner = self.class.new_provisioner(options)
        provisioner.async.down(job.freeze, environment.to_s)
        job.ticket
      ensure
        provisioner.terminate if provisioner && provisioner.alive?
      end

      def finalize
        log.info { "Provision Manager stopping..." }
      end
    end
  end
end
