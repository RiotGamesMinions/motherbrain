module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class PluginResource < ApiClient::Resource
      # @param [String] name
      # @param [String, nil] version (nil)
      #
      # @return [Hash]
      def find(name, version = nil)
        result = if version.nil?
          get("/plugins/#{name}.json").body
        else
          get("/plugins/#{name}/#{version.gsub('.', '_')}.json").body
        end

        MultiJson.decode result
      end

      # @return [Array]
      def list
        MultiJson.decode get('/plugins.json').body
      end
    end
  end
end
