require 'ridley/middleware'

module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Connection < Faraday::Connection
      include Celluloid

      VALID_OPTIONS = [
        :retries,
        :retry_interval,
        :ssl,
        :proxy
      ]

      def initialize(server_url, options = {})
        options = options.slice(*VALID_OPTIONS).reverse_merge(retries: 5, retry_interval: 0.5)

        options[:builder] = Faraday::Builder.new do |b|
          b.response :json
          b.request :retry,
            max: @retries,
            interval: @retry_interval,
            exceptions: [
              Errno::ETIMEDOUT,
              Faraday::Error::TimeoutError
            ]

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
