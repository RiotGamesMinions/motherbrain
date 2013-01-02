module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Resource
      extend Forwardable
      include Celluloid

      # @param [ApiClient] client
      def initialize(client)
        @connection = client.connection
      end

      private

        # @return [ApiClient::Connection]
        attr_reader :connection

        def_delegator :connection, :get
        def_delegator :connection, :put
        def_delegator :connection, :post
        def_delegator :connection, :delete
        def_delegator :connection, :head

        # Perform a DELETE to the target resource and return the decoded JSON response body
        def json_delete(*args)
          MultiJson.decode delete(*args).body
        end

        # Perform a GET to the target resource and return the decoded JSON response body
        def json_get(*args)
          MultiJson.decode get(*args).body
        end

        # Perform a PUT to the target resource and return the decoded JSON response body
        def json_put(*args)
          MultiJson.decode put(*args).body
        end

        # Perform a POST to the target resource and return the decoded JSON response body
        def json_post(*args)
          MultiJson.decode post(*args).body
        end
    end
  end
end
