module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class ConfigResource < ApiClient::Resource
      # @return [MB::Config]
      def show
        MB::Config.from_json(connection.get('/config.json').body)
      end
    end
  end
end
