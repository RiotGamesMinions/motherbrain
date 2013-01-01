module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Connection < Faraday::Connection
      include Celluloid
    end
  end
end
