module MotherBrain
  class ApiClient
    # @author Jamie Winsor <reset@riotgames.com>
    class PluginResource < ApiClient::Resource
      # List the commands of a plugin
      #
      # @param [String] name
      # @param [String, nil] version (nil)
      #
      # @return [Hash]
      def commands(name, version = nil)
        version = version.nil? ? "latest" : version.gsub('.', '_')

        json_get("/plugins/#{name}/#{version}/commands.json")
      end

      # List the components of a plugin
      #
      # @param [String] name
      # @param [String, nil] version (nil)
      #
      # @return [Hash]
      def components(name, version = nil)
        version = version.nil? ? "latest" : version.gsub('.', '_')

        json_get("/plugins/#{name}/#{version}/components.json")
      end

      # List the commands of a component of a plugin
      #
      # @param [String] name
      # @param [String, nil] version
      # @param [String] component
      #
      # @return [Hash]
      def component_commands(name, version, component)
        version = version.nil? ? "latest" : version.gsub('.', '_')

        json_get("/plugins/#{name}/#{version}/components/#{component}/commands.json")
      end

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

      # @param [String] name
      #
      # @return [Hash]
      def latest(name)
        json_get("/plugins/#{name}/latest.json")
      end

      # @return [Array]
      def list
        json_get('/plugins.json')
      end
    end
  end
end
