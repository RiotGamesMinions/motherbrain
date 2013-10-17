module MotherBrain
  class ApiClient
    class ConfigResource < ApiClient::Resource
      # @return [MB::Config]
      def show
        MB::Config.from_hash(connection.get('/config.json').body)
      end
    end
  end
end
