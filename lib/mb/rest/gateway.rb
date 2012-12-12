require 'reel'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Gateway < Reel::Server
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

      # @option options [String] :host ('0.0.0.0')
      # @option options [Integer] :port (1984)
      # @option options [Boolean] :quiet (false)
      # @option options [Integer] :workers (10)
      def initialize(options = {})
        @options       = DEFAULT_OPTIONS.merge(options)
        @options[:app] = REST::API.new
        
        @pool = ::Reel::RackWorker.pool_link(size: @options[:workers], args: [::Rack::Handler::Reel.new(@options)])

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
    end
  end
end
