require 'faraday'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ApiClient
    # @api private
    class Connection < Faraday::Connection
      include Celluloid
    end

    DEFAULT_URL = "http://#{REST::Gateway::DEFAULT_OPTIONS[:host]}:#{REST::Gateway::DEFAULT_OPTIONS[:port]}"

    extend Forwardable
    include Celluloid

    trap_exit :restart_connection

    attr_reader :pool
    attr_reader :options

    def_delegator :pool, :get
    def_delegator :pool, :put
    def_delegator :pool, :post
    def_delegator :pool, :delete
    def_delegator :pool, :head

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

      @options = { size: 4, args: [options] }
      @pool    = ApiClient::Connection.pool_link(@options)
    end

    def config
      MB::Config.from_json(get('/config.json').body)
    end

    def finalize
      pool.terminate if pool.alive?
    end

    private

      def restart_connection(actor, reason)
        return unless reason

        @connection = ApiClient::Connection.pool_link(self.options)
      end
  end
end
