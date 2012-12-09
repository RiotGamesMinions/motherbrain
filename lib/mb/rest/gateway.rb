require 'reel'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Gateway < Reel::Server
      DEFAULT_BIND_ADDRESS = '127.0.0.1'.freeze
      DEFAULT_PORT = 1984.freeze

      # @option options [String] :bind_address (DEFAULT_BIND_ADDRESS)
      # @option options [Integer] :port (DEFAULT_PORT)
      def initialize(options = {})
        bind_address = options[:bind_address] || DEFAULT_BIND_ADDRESS
        port         = options[:port] || DEFAULT_PORT

        super(bind_address, port, &method(:handler))
      end

      def handler(connection)
        case connection.request.try(:url)
        when '/config.json'
          connection.respond Response.new(:ok, Application.config)
        else
          connection.respond :not_found
        end
      end

      class Response < Reel::Response
        DEFAULT_HEADERS = {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }.freeze

        # @param [#to_sym] status
        # @param [Object] body
        # @param [Hash] headers
        def initialize(status, body = {}, headers = {})
          headers.reverse_merge!(DEFAULT_HEADERS)

          super(status, headers, MultiJson.encode(body))
        end
      end
    end
  end
end
