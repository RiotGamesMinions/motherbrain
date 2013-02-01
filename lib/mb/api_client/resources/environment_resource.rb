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
      # @option options [Hash] :component_versions (Hash.new)
      #   Hash of components and the versions to set them to
      # @option options [Hash] :cookbook_versions (Hash.new)
      #   Hash of cookbooks and the versions to set them to
      # @option options [Hash] :environment_attributes (Hash.new)
      #   Hash of additional attributes to set on the environment
      # @option options [Boolean] :skip_bootstrap (false)
      #   skip automatic bootstrapping of the created environment
      # @option options [Boolean] :force (false)
      #   force provisioning nodes to the environment even if the environment is locked
      def provision(id, plugin, manifest, options = {})
        body = options.merge(
          manifest: manifest,
          plugin: {
            name: plugin,
            version: options[:version]
          }
        )
        
        json_post("/environments/#{id}.json", MultiJson.encode(body))
      end
    end
  end
end
