require 'reel'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Gateway < Reel::Server
      class << self
        # @raise [Celluloid::DeadActorError] if rest gateway has not been started
        #
        # @return [Celluloid::Actor(Gateway)]
        def instance
          Celluloid::Actor[:rest_gateway] or raise Celluloid::DeadActorError, "REST gateway not running"
        end
      end

      extend Forwardable
      include Celluloid
      include MB::Logging

      DEFAULT_OPTIONS = {
        host: '0.0.0.0',
        port: 1984,
        quiet: false,
        workers: 10
      }.freeze

      # @return [Hash]
      attr_reader :options

      def_delegator :handler, :rack_app

      # @option options [String] :host ('0.0.0.0')
      # @option options [Integer] :port (1984)
      # @option options [Boolean] :quiet (false)
      # @option options [Integer] :workers (10)
      def initialize(options = {})
        @options       = DEFAULT_OPTIONS.merge(options)
        @options[:app] = REST::API.new
        
        @handler = ::Rack::Handler::Reel.new(@options)
        @pool = ::Reel::RackWorker.pool_link(size: @options[:workers], args: [@handler])

        MB.log.info "MotherBrain REST Gatway: Listening on #{@options[:host]}:#{@options[:port]}"
        super(@options[:host], @options[:port], &method(:on_connect))
      end

      # @param [Reel::Connection] connection
      def on_connect(connection)
        pool.handle(connection.detach)
      end

      def finalize
        log.info { "REST Gateway stopping..." }
      end

      private

        # @return [Reel::RackWorker]
        attr_reader :pool
        attr_reader :handler
    end
  end
end
