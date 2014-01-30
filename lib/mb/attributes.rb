module MotherBrain
  module Attributes
    include Celluloid
    include MB::Logging

    finalizer :finalize_callback

    def initialize
      log.debug { "Attributes viewer starting..." }
    end
\
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
    def attributes(job, environment, plugin, options = {})
      log.debug { "Attributes job running." }
      # worker = Worker.new(job, environment.freeze, plugin.freeze, options.freeze)
      # worker.run
    ensure
      # worker.terminate if worker && worker.alive?
      # job.terminate if job && job.alive?
    end

    private

      def finalize_callback
        log.debug { "Attributes viewer stopping..." }
      end
  end
end
