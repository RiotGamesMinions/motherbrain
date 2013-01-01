module MotherBrain
  class ApiClient
    class PluginResource < ApiClient::Resource
      def list
        MultiJson.decode get('/plugins.json').body
      end
    end
  end
end
