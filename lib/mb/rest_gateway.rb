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
      port: 26100,
      quiet: false,
      workers: 10
    }.freeze

    VALID_OPTIONS = [
      :host,
      :port,
      :quiet,
      :workers
    ].freeze

    # @return [String]
    attr_reader :host
    # @return [Integer]
    attr_reader :port
    # @return [Integer]
    attr_reader :workers

    def_delegator :handler, :rack_app

    finalizer :finalize_callback

    # @option options [String] :host ('0.0.0.0')
    # @option options [Integer] :port (26100)
    # @option options [Boolean] :quiet (false)
    # @option options [Integer] :workers (10)
    def initialize(options = {})
      log.info { "REST Gateway starting..." }

      options  = DEFAULT_OPTIONS.merge(options.slice(*VALID_OPTIONS))
      options[:app] = MB::Api.new

      @host    = options[:host]
      @port    = options[:port]
      @workers = options[:workers]
      @handler = ::Rack::Handler::Reel.new(options)
      @pool    = ::Reel::RackWorker.pool(size: @workers, args: [ @handler ])

      log.info { "REST Gateway listening on #{@host}:#{@port}" }
      super(@host, @port, &method(:on_connect))
    end

    # @param [Reel::Connection] connection
    def on_connect(connection)
      pool.handle(connection.detach)
    end

    private

      # @return [Reel::RackWorker]
      attr_reader :pool
      # @return [Rack::Handler::Reel]
      attr_reader :handler

      def finalize_callback
        log.info { "REST Gateway stopping..." }
        pool.terminate if pool && pool.alive?
      end
  end
end
