module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class EnvironmentManager
    class << self
      # @raise [Celluloid::DeadActorError] if the environment manager has not been started
      #
      # @return [Celluloid::Actor(EnvironmentManager)]
      def instance
        MB::Application[:environment_manager] or raise Celluloid::DeadActorError, "environment manager not running"
      end
    end

    include Celluloid
    include MB::Logging
    include MB::Locks
    include MB::Mixin::Services

    def initialize
      log.info { "Environment Manager starting..." }
    end

    # Configure a target environment with the given attributes
    #
    # @param [#to_s] id
    #   identifier for the environment to configure
    #
    # @option options [Hash] :attributes (Hash.new)
    #   a hash of attributes to merge with the existing attributes of an environment
    # @option options [Boolean] :force (false)
    #   force configure even if the environment is locked
    #
    # @note attributes will be set at the 'default' level and will be merged into the
    #   existing attributes of the environment
    #
    # @return [JobTicket]
    def configure(id, options = {})
      options = options.reverse_merge(
        attributes: Hash.new,
        force: false
      )

      job         = Job.new(:configure_environment)
      environment = find(id)

      async(:_configure_, environment, job, options)

      job.ticket      
    end

    def finalize
      log.info { "Environment Manager stopping..." }
    end

    # Find an environment on the remote Chef server
    #
    # @param [#to_s] id
    #   identifier for the environment to find
    #
    # @raise [EnvironmentNotFound] if the given environment does not exist
    #
    # @return [Ridley::EnvironmentResource]
    def find(id)
      ridley.environment.find!(id)
    rescue Ridley::Errors::ResourceNotFound => ex
      abort EnvironmentNotFound.new("no environment '#{id}' was found")
    end

    # Returns a list of environments present on the remote server
    #
    # @return [Array<Ridley::EnvironmentResource>]
    def list
      ridley.environment.all
    end

    # Performs the heavy lifting for {#configure}
    #
    # @param [Ridley::EnvironmentResource] environment
    #   the environment to lock and configure
    # @param [MB::Job] job
    #   a job to update with progress
    # @param [Hash] options
    #   see {#configure} for deatils
    #
    # @note making this a separate function allows us to run the heavy lifting of {#configure} in
    #   an asynchronous manner
    #
    # @api private
    def _configure_(environment, job, options = {})
      chef_synchronize(chef_environment: environment.name, force: options[:force], job: job) do
        environment.default_attributes.deep_merge!(options[:attributes])
        job.status = "saving updated environment"
        environment.save

        job.status = "searching for nodes in the environment"
        nodes = ridley.search(:node, "chef_environment:#{environment.name}")

        job.status = "performing chef_run on #{nodes.length} nodes"
        nodes.collect do |node|
          node_querier.future(:chef_run, node.public_hostname)
        end.map(&:value)

        job.status = "finished chef_run on #{nodes.length} nodes"
      end
    end
  end
end
