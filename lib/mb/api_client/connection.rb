module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Connection < Faraday::Connection
      include Celluloid

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
