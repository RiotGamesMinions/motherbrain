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

        super(bind_address, port, &method(:on_connect))
      end

      def on_connect(connection)
        while request = connection.request
          case request
          when Reel::Request
            route_request connection, request
          when Reel::WebSocket
            MB.log.warn "Recieved an unhandled websocket request: #{request}"
            connection.close
          end
        end
      end

      def route_request(connection, request)
        case request.url
        when '/config.json'
          connection.respond json(:ok, Application.config)
        when '/plugins.json'
          connection.respond json(:ok, Application.plugin_srv.plugins)
        else
          connection.respond :not_found, "not found"
        end
      end

      private

        def json(*args)
          JSONResponse.new(*args)
        end

      class JSONResponse < Reel::Response
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
