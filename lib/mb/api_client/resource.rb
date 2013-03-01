module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Resource
      include Celluloid

      # @param [ApiClient] client
      def initialize(client)
        @connection = client.connection
      end

      private

        # @return [ApiClient::Connection]
        attr_reader :connection

        # Perform a DELETE to the target resource and return the decoded JSON response body
        def json_delete(*args)
          connection.delete(*args).body
        end

        # Perform a GET to the target resource and return the decoded JSON response body
        def json_get(*args)
          connection.get(*args).body
        end

        # Perform a PUT to the target resource and return the decoded JSON response body
        def json_put(*args)
          connection.put(*args).body
        end

        # Perform a POST to the target resource and return the decoded JSON response body
        def json_post(*args)
          connection.post(*args).body
        end
    end
  end
end
