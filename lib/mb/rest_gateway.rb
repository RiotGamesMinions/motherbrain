require 'reel'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class RestGateway < Reel::Server
    class << self
      # @raise [Celluloid::DeadActorError] if rest gateway has not been started
      #
      # @return [Celluloid::Actor(Gateway)]
      def instance
        MB::Application[:rest_gateway] or raise Celluloid::DeadActorError, "REST Gateway not running"
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

    finalizer do
      log.info { "REST Gateway stopping..." }
      pool.terminate if pool && pool.alive?
    end

    # @option options [String] :host ('0.0.0.0')
    # @option options [Integer] :port (1984)
    # @option options [Boolean] :quiet (false)
    # @option options [Integer] :workers (10)
    def initialize(options = {})
      @options       = DEFAULT_OPTIONS.merge(options)
      @options[:app] = MB::Api.new

      @handler = ::Rack::Handler::Reel.new(@options)
      @pool = ::Reel::RackWorker.pool(size: @options[:workers], args: [@handler])

      log.info "MotherBrain REST Gatway: Listening on #{@options[:host]}:#{@options[:port]}"
      super(@options[:host], @options[:port], &method(:on_connect))
    end

    # @param [Reel::Connection] connection
    def on_connect(connection)
      pool.handle(connection.detach)
    end

    private

      # @return [Reel::RackWorker]
      attr_reader :pool
      attr_reader :handler
  end
end
