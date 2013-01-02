require 'faraday'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ApiClient < Celluloid::SupervisionGroup
    autoload :Connection, 'mb/api_client/connection'
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

    # @option options [String] :url
    #   URL to REST Gateway
    # @option options [Hash] :params
    #   URI query unencoded key/value pairs
    # @option options [Hash] :headers
    #   unencoded HTTP header key/value pairs
    # @option options [Hash] :request
    #   request options
    # @option options [Hash] :ssl
    #   * :verify (Boolean) [true] set to false to disable SSL verification
    # @option options [URI, String, Hash] :proxy
    #   URI, String, or Hash of HTTP proxy options
    # @option options [Class] parallel_manager
    #   the parallel http manager to use
    def initialize(options = {})
      options = options.reverse_merge(
        url: DEFAULT_URL,
        builder: Faraday::Builder.new { |b| b.adapter :net_http_persistent }
      )

      super(Celluloid::Registry.new)
      pool(ApiClient::Connection, size: 4, args: [options], as: :connection_pool)
    end

    def finalize
      connection.terminate if connection.alive?
    end

    def connection
      registry[:connection_pool]
    end

    protected

      attr_reader :registry
  end
end
