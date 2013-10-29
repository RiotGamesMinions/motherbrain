module MotherBrain
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
    include MB::Mixin::Locks
    include MB::Mixin::Services

    finalizer :finalize_callback

    def initialize
      log.debug { "Environment Manager starting..." }
    end

    # Asynchronously configure a target environment with the given attributes
    #
    # @param [String] id
    #   identifier of the environment to configure
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
    def async_configure(id, options = {})
      job = Job.new(:environment_configure)
      async(:configure, job, id, options)

      job.ticket
    end

    # Configure a target environment with the given attributes
    #
    # @param [MB::Job] job
    #   a job to update with progress
    # @param [String] id
    #   identifier of the environment to configure
    #
    # @option options [Hash] :attributes (Hash.new)
    #   a hash of attributes to merge with the existing attributes of an environment
    # @option options [Boolean] :force (false)
    #   force configure even if the environment is locked
    #
    # @api private
    def configure(job, id, options = {})
      options = options.reverse_merge(
        attributes: Hash.new,
        force: false
      )

      node_successes_count = 0
      node_successes = Array.new

      node_failures_count  = 0
      node_failures = Array.new

      environment = find(id)
      job.report_running("Finding environment #{environment.name}")

      chef_synchronize(chef_environment: environment.name, force: options[:force], job: job) do
        job.set_status("Saving updated environment")
        environment.default_attributes.deep_merge!(options[:attributes])
        environment.save

        job.set_status("Searching for nodes in the environment")
        nodes = nodes_for_environment(environment.name)

        job.set_status("Performing a chef client run on #{nodes.length} nodes")
        nodes.collect do |node|
          node_querier.future(:chef_run, node.public_hostname)
        end.each do |future|
          begin
            response = future.value
            node_successes_count += 1
            node_successes << response.host
          rescue RemoteCommandError => error
            node_failures_count += 1
            node_failures << error.host
          end
        end
      end

      if node_failures_count > 0
        job.report_failure("chef client run failed on #{node_failures_count} node(s) - #{node_failures.join(', ')}")
      else
        job.report_success("Finished chef client run on #{node_successes_count} node(s) - #{node_successes.join(', ')}")
      end
    rescue => ex
      job.report_failure(ex)
    ensure
      job.terminate if job && job.alive?
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
      unless environment = ridley.environment.find(id)
        abort EnvironmentNotFound.new(id)
      end

      environment
    end

    # Creates an environment
    #
    # @param [#to_s] name
    #
    # @return [Ridley::EnvironmentResource]
    def create(name)
      ridley.environment.create(name: name)
    rescue => error
      abort error
    end

    # Destroys an environment
    #
    # @param [#to_s] name
    #
    # @return [Ridley::EnvironmentResource, nil]
    def destroy(name)
      ridley.environment.delete(name)
    end

    # Returns a list of environments present on the remote server
    #
    # @return [Array<Ridley::EnvironmentResource>]
    def list
      ridley.environment.all
    end

    # Removes all nodes and clients from the Chef server for a given environment
    #
    # @param [String] name
    def purge_nodes(name)
      nodes = nodes_for_environment(name)
      futures = []

      nodes.each do |node|
        futures << ridley.client.future(:delete, node)
        futures << ridley.node.future(:delete, node)
      end

      futures.map(&:value)
    end

    # Returns an array of nodes for an environment
    #
    # @param [String] name
    #
    # @return [Array(Ridley::NodeObject)]
    def nodes_for_environment(name)
      ridley.search(:node, "chef_environment:#{name}")
    end

    private

      def finalize_callback
        log.debug { "Environment Manager stopping..." }
      end
  end
end
