require 'newrelic_rpm'

module MotherBrain
  class ApiClient

    require_relative 'api_client/connection'
    require_relative 'api_client/middleware'
    require_relative 'api_client/resource'
    require_relative 'api_client/resources'

    class ConnectionSupervisor < Celluloid::SupervisionGroup
      def initialize(registry, url, options)
        super(registry)
        pool(ApiClient::Connection, size: 4, args: [url, options], as: :connection_pool)
      end
    end

    class ResourcesSupervisor < Celluloid::SupervisionGroup
      def initialize(registry, connection_registry, options)
        super(registry)
        supervise_as :config_resource, ApiClient::ConfigResource, connection_registry
        supervise_as :environment_resource, ApiClient::EnvironmentResource, connection_registry
        supervise_as :job_resource, ApiClient::JobResource, connection_registry
        supervise_as :plugin_resource, ApiClient::PluginResource, connection_registry
      end
    end

    DEFAULT_URL = "http://#{RestGateway::DEFAULT_OPTIONS[:host]}:#{RestGateway::DEFAULT_OPTIONS[:port]}"

    extend Forwardable
    include Celluloid

    def_delegator :connection, :get
    def_delegator :connection, :put
    def_delegator :connection, :post
    def_delegator :connection, :delete
    def_delegator :connection, :head

    finalizer :finalize_callback

    # @param [String] url
    #   URL to REST Gateway
    #
    # @option options [Integer] :retries (5)
    #   retry requests on 5XX failures
    # @option options [Float] :retry_interval (0.5)
    # @option options [Hash] :ssl
    #   * :verify (Boolean) [true] set to false to disable SSL verification
    # @option options [URI, String, Hash] :proxy
    #   URI, String, or Hash of HTTP proxy options
    def initialize(url = DEFAULT_URL, options = {})
      @options = options

      @connection_registry = Celluloid::Registry.new
      @resources_registry = Celluloid::Registry.new

      @connection_supervisor = ConnectionSupervisor.new(@connection_registry, url, @options)
      @resources_supervisor = ResourcesSupervisor.new(@resources_registry, @connection_registry, @options)
    end

    def connection
      @connection_registry[:connection_pool]
    end

    def config
      @resources_registry[:config_resource]
    end

    def environment
      @resources_registry[:environment_resource]
    end

    def job
      @resources_registry[:job_resource]
    end

    def plugin
      @resources_registry[:plugin_resource]
    end

    private

      def finalize_callback
        @connection_supervisor.terminate if @connection_supervisor && @connection_supervisor.alive?
        @resources_supervisor.terminate if @resources_supervisor && @resources_supervisor.alive?
      end
  end
end
