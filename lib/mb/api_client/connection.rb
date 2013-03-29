require 'ridley/middleware'
require 'mb/api_client/middleware'

module MotherBrain
  class ApiClient
    # @author Jamie Winsor <reset@riotgames.com>
    # @api private
    class Connection < Faraday::Connection
      include Celluloid

      VALID_OPTIONS = [
        :retries,
        :retry_interval,
        :ssl,
        :proxy
      ]

      # @param [String] server_url
      #
      # @option options [Integer] :retries (5)
      #   retry requests on 5XX failures
      # @option options [Float] :retry_interval (0.5)
      #   how often we should pause between retries
      # @option options [Hash] :ssl
      #   * :verify (Boolean) [true] set to false to disable SSL verification
      # @option options [URI, String, Hash] :proxy
      #   URI, String, or Hash of HTTP proxy options
      def initialize(server_url, options = {})
        options = options.slice(*VALID_OPTIONS).reverse_merge(retries: 5, retry_interval: 0.5)

        options[:builder] = Faraday::Builder.new do |b|
          b.response :json
          b.request :retry,
            max: options[:retries],
            interval: options[:retry_interval],
            exceptions: [
              Errno::ETIMEDOUT,
              Faraday::Error::TimeoutError
            ]
          b.request :motherbrain_auth
          b.adapter :net_http_persistent
        end

        super(server_url, options)
      end

      # Override Faraday::Connection#run_request to catch exceptions raised in any
      # middleware and then re-raise them with Celluloid#abort so we don't crash
      # the connection.
      def run_request(*args)
        super
      rescue => ex
        abort(ex)
      end
    end
  end
end
