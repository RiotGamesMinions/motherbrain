module MotherBrain
  class ApiClient
    class Resource
      include Celluloid

      # @param [ApiClient] client
      def initialize(connection_registry)
        @connection_registry = connection_registry
      end

      # @return [ApiClient::Connection]
      def connection
        @connection_registry[:connection_pool]
      end

      private

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
