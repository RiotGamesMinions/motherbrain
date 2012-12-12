require 'faraday'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Client
      DEFAULT_URL = "http://#{REST::Gateway::DEFAULT_OPTIONS[:host]}:#{REST::Gateway::DEFAULT_OPTIONS[:port]}".freeze

      extend Forwardable

      def_delegator :connection, :get
      def_delegator :connection, :put
      def_delegator :connection, :post
      def_delegator :connection, :delete
      def_delegator :connection, :head

      # @option options [String] :url
      #   url to REST Gateway
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
        url         = options[:url] || DEFAULT_URL
        @connection = Faraday::Connection.new(url, options)
      end

      def config
        MB::Config.from_json(connection.get('/config.json').body)
      end

      private

        attr_reader :connection
    end
  end
end
