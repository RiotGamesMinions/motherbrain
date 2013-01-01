module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Resource
      extend Forwardable
      include Celluloid

      # @param [ApiClient::Connection] connection
      def initialize(connection)
        @connection = connection
      end

      private

        # @return [ApiClient::Connection]
        attr_reader :connection

        def_delegator :connection, :get
        def_delegator :connection, :put
        def_delegator :connection, :post
        def_delegator :connection, :delete
        def_delegator :connection, :head

        # Perform a GET to the target resource and return the decoded JSON response body
        def json_get(*args)
          MultiJson.decode get(*args).body
        end
    end
  end
end
