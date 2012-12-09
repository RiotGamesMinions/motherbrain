require 'reel'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Gateway < Reel::Server
      DEFAULT_BIND_ADDRESS = '127.0.0.1'.freeze
      DEFAULT_PORT = 1984.freeze
      DEFAULT_HEADERS = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }.freeze

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
          connection.respond Reel::Response.new(:ok, DEFAULT_HEADERS.dup, Application.config.to_json(pretty: true))
        else
          connection.respond :ok, "hello, world!"
        end
      end
    end
  end
end
