module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Handles upgrading nodes in already environments.
    class Manager
      class << self
        # @raise [Celluloid::DeadActorError] if Upgrade Manager has not been started
        #
        # @return [Celluloid::Actor(Upgrade::Manager)]
        def instance
          MB::Application[:upgrade_manager] or raise Celluloid::DeadActorError, "upgrade manager not running"
        end
      end

      include Celluloid
      include MB::Logging

      finalizer do
        log.info { "Upgrade Manager stopping..." }
      end

      def initialize
        log.info { "Upgrade Manager starting..." }
      end

      # Asynchronously upgrade an environment
      #
      # @param [String] environment
      #   name of the environment to upgrade
      # @param [MB::Plugin] plugin
      #   plugin to use for performing the upgrade on the environment
      #
      # @option options [Hash] component_versions
      #   Hash of components and the versions to set them to
      # @option options [Hash] cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] environment_attributes
      #   any additional attributes to set on the environment
      # @option options [String] environment_attributes_file
      #   any additional attributes to set on the environment via a json file
      # @option options [Boolean] :force
      #   Force any locks to be overwritten
      #
      # @return [JobTicket]
      def async_upgrade(environment, plugin, options = {})
        job = Job.new(:upgrade)

        async(:upgrade, job, environment, plugin, options)

        job.ticket
      end

      # Synchronously upgrade an environment
      #
      # @param [MB::Job] job
      # @param [String] environment
      #   name of the environment to upgrade
      # @param [MB::Plugin] plugin
      #   plugin to use for performing the upgrade on the environment
      #
      # @option options [Hash] component_versions
      #   Hash of components and the versions to set them to
      # @option options [Hash] cookbook_versions
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] environment_attributes
      #   any additional attributes to set on the environment
      # @option options [String] environment_attributes_file
      #   any additional attributes to set on the environment via a json file
      # @option options [Boolean] :force
      #   Force any locks to be overwritten
      #
      # @return [Job]
      def upgrade(job, environment, plugin, options = {})
        worker = Worker.new(job, environment.freeze, plugin.freeze, options.freeze)
        worker.run
      ensure
        worker.terminate if worker && worker.alive?
        job.terminate if job && job.alive?
      end
    end
  end
end
