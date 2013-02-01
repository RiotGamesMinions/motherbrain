module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class EnvironmentResource < ApiClient::Resource
      # @param [String] id
      #   name of the environment to update
      # @param [String] plugin
      #   name of the plugin to use
      # @param [Bootstrap::Manifest] manifest
      #
      # @option options [String] :version
      #   version of the plugin to use
      # @option options [Boolean] :force
      # @option options [Array] :hints
      def bootstrap(id, plugin, manifest, options = {})
        body = {
          manifest: manifest,
          plugin: {
            name: plugin,
            version: options[:version]
          },
          force: options[:force],
          hints: options[:hints]
        }

        json_put("/environments/#{id}.json", MultiJson.encode(body))
      end

      # Configure a target environment with the given attributes
      #
      # @param [#to_s] id
      #   identifier for the environment to configure
      #
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to merge with the existing attributes of an environment
      # @option options [Boolean] :force (false)
      #   force configure even if the environment is locked
      #
      # @note attributes will be set at the 'default' level and will be merged into the
      #   existing attributes of the environment
      def configure(id, options = {})
        body = {
          attributes: options[:attributes],
          force: false
        }

        json_post("/environments/#{id}/configure.json", MultiJson.encode(body))
      end

      # @param [String] id
      def destroy(id)
        json_delete("/environments/#{id}.json")
      end

      # @param [String] id
      #   name of the environment to create
      # @param [String] plugin
      #   name of the plugin to use
      # @param [Provisioner::Manifest] manifest
      #
      # @option options [String] :version
      #   version of the plugin to use
      def provision(id, plugin, manifest, options = {})
        body = {
          manifest: manifest,
          plugin: {
            name: plugin,
            version: options[:version]
          }
        }
        
        json_post("/environments/#{id}.json", MultiJson.encode(body))
      end
    end
  end
end
