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

    DEFAULT_URL = "http://#{REST::Gateway::DEFAULT_OPTIONS[:host]}:#{REST::Gateway::DEFAULT_OPTIONS[:port]}"

    extend Forwardable

    trap_exit :restart_connection

    attr_reader :pool
    attr_reader :options

    def_delegator :pool, :get
    def_delegator :pool, :put
    def_delegator :pool, :post
    def_delegator :pool, :delete
    def_delegator :pool, :head

    resource ApiClient::ConfigResource, :config
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

      @registry = Celluloid::Registry.new
      @options = { size: 4, args: [options] }
      @pool    = ApiClient::Connection.pool_link(@options)

      super(@registry)
    end

    def finalize
      pool.terminate if pool.alive?
    end

    protected

      attr_reader :registry

    private

      def restart_connection(actor, reason)
        return unless reason

        @connection = ApiClient::Connection.pool_link(self.options)
      end
  end
end
