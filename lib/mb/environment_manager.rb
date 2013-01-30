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

      async(:_configure_, id, job, options)

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
      environment = ridley.environment.find!(id)
    rescue Ridley::Errors::ResourceNotFound => ex
      abort EnvironmentNotFound.new("no environment '#{id}' was found")
    end

    # Returns a list of environments present on the remote server
    #
    # @return [Array<Ridley::EnvironmentResource>]
    def list
      ridley.environment.all
    end

    private

      # Performs the heavy lifting for {#configure}
      #
      # @note making this a separate function allows us to run the heavy lifting of {#configure} in
      #   an asynchronous manner
      def _configure_(id, job, options = {})
        chef_synchronize(chef_environment: environment.name, force: options[:force], job: job) do
          environment.default_attributes.deep_merge!(options[:attributes])
          environment.save

          ridley.search(:node, "environment: #{environment.name}").collect do |node|
            node_querier.future(:chef_run, node.public_hostname)
          end.map(&:value)
        end
      end
  end
end
