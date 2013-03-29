module MotherBrain
  class ApiClient
    # @author Jamie Winsor <reset@riotgames.com>
    class ConfigResource < ApiClient::Resource
      # @return [MB::Config]
      def show
        MB::Config.from_json(connection.get('/config.json').body)
      end
    end
  end
end
