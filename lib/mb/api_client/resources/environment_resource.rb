module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class EnvironmentResource < ApiClient::Resource
      # @param [String] id
      def destroy(id)
        MultiJson.decode delete("/environments/#{id}.json").body
      end
    end
  end
end
