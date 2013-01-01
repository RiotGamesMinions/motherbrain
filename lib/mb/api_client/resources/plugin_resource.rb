module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class PluginResource < ApiClient::Resource
      # @param [String] name
      # @param [String, nil] version (nil)
      #
      # @return [Hash]
      def find(name, version = nil)
        if version.nil?
          json_get("/plugins/#{name}.json")
        else
          json_get("/plugins/#{name}/#{version.gsub('.', '_')}.json")
        end
      end

      # @return [Array]
      def list
        json_get('/plugins.json')
      end
    end
  end
end
