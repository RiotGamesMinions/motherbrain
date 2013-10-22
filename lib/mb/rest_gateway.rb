require 'reel/rack'

module MotherBrain
  class RestGateway < Reel::Rack::Server
    class << self
      # @raise [Celluloid::DeadActorError] if rest gateway has not been started
      #
      # @return [Celluloid::Actor(Gateway)]
      def instance
        MB::Application[:rest_gateway] or raise Celluloid::DeadActorError, "REST Gateway not running"
      end

      # Start the REST Gateway and add it to the application's registry.
      #
      # @note you probably don't want to manually start the REST Gateway unless you are testing. Start
      #   the entire application with {MB::Application.run}
      def start(options = {})
        MB::Application[:rest_gateway] = new(options)
      end

      # Stop the currently running REST Gateway
      #
      # @note you probably don't want to manually stop the REST Gateway unless you are testing. Stop
      #   the entire application with {MB::Application.stop}
      def stop
        instance.shutdown
      end
    end

    include MB::Logging

    DEFAULT_OPTIONS = {
      host: '0.0.0.0',
      port: 26100,
      quiet: false
    }.freeze

    VALID_OPTIONS = [
      :host,
      :port,
      :quiet
    ].freeze

    finalizer :finalize_callback

    # @option options [String] :host ('0.0.0.0')
    # @option options [Integer] :port (26100)
    # @option options [Boolean] :quiet (false)
    def initialize(options = {})
      log.info { "REST Gateway starting..." }

      options = DEFAULT_OPTIONS.merge(options.slice(*VALID_OPTIONS))
      app     = MB::API::Application.new

      # reel-rack uses Rack standard capitalizations in > 0.0.2
      options[:Host] = options[:host]
      options[:Port] = options[:port]

      log.info { "REST Gateway listening on #{options[:host]}:#{options[:port]}" }
      super(app, options)
    end

    private

      def finalize_callback
        log.info { "REST Gateway stopping..." }
        self.shutdown
      end
  end
end
