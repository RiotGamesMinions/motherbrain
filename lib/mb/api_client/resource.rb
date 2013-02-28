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
          MultiJson.decode connection.delete(*args).body
        end

        # Perform a GET to the target resource and return the decoded JSON response body
        def json_get(*args)
          MultiJson.decode connection.get(*args).body
        end

        # Perform a PUT to the target resource and return the decoded JSON response body
        def json_put(*args)
          MultiJson.decode connection.put(*args).body
        end

        # Perform a POST to the target resource and return the decoded JSON response body
        def json_post(*args)
          MultiJson.decode connection.post(*args).body
        end
    end
  end
end
