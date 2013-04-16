require 'faraday'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class ApiClient < Celluloid::SupervisionGroup
    autoload :Connection, 'mb/api_client/connection'
    autoload :Middleware, 'mb/api_client/middleware'
    autoload :Resource, 'mb/api_client/resource'

    require 'mb/api_client/resources'

    class << self
      def resource(klass, name)
        define_method(name) do
          if registry[name].nil?
            supervise_as(name, klass, Celluloid::Actor.current)
          end
          registry[name]
        end
      end
    end

    DEFAULT_URL = "http://#{RestGateway::DEFAULT_OPTIONS[:host]}:#{RestGateway::DEFAULT_OPTIONS[:port]}"

    extend Forwardable

    def_delegator :connection, :get
    def_delegator :connection, :put
    def_delegator :connection, :post
    def_delegator :connection, :delete
    def_delegator :connection, :head

    resource ApiClient::ConfigResource, :config
    resource ApiClient::EnvironmentResource, :environment
    resource ApiClient::JobResource, :job
    resource ApiClient::PluginResource, :plugin

    finalizer do
      connection.terminate if connection.alive?
    end

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
      super(Celluloid::Registry.new)
      pool(ApiClient::Connection, size: 4, args: [url, options], as: :connection_pool)
    end

    def connection
      registry[:connection_pool]
    end

    protected

      attr_reader :registry
  end
end
