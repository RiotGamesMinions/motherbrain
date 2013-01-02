module MotherBrain
  class ApiClient
    # @author Jamie Winsor <jamie@vialstudios.com>
    class EnvironmentResource < ApiClient::Resource
      # @param [String] id
      # @param [String] plugin
      # @param [Bootstrap::Manifest] manifest
      #
      # @option options [String] :version
      # @option options [Boolean] :force
      # @option options [Array] :hints
      def bootstrap(id, plugin, manifest, options = {})
        body = {
          manifest: manifest,
          environment: id
        }

        if options[:version].nil?
          json_post("/plugins/#{plugin}/bootstrap.json", MultiJson.encode(body))
        else
          version = options[:version].gsub('.', '_')
          body = body.merge(options.slice(:force, :hints))
          json_post("/plugins/#{plugin}/#{version}/bootstrap.json", MultiJson.encode(body))
        end
      end

      # @param [String] id
      def destroy(id)
        json_delete("/environments/#{id}.json")
      end

      # @param [String] id
      # @param [String] plugin
      # @param [Provisioner::Manifest] manifest
      #
      # @option options [String] :version
      def provision(id, plugin, manifest, options = {})
        body = {
          manifest: manifest,
          environment: id
        }

        if options[:version].nil?
          json_post("/plugins/#{plugin}/provision.json", MultiJson.encode(body))
        else
          version = options[:version].gsub('.', '_')
          json_post("/plugins/#{plugin}/#{version}/provision.json", MultiJson.encode(body))
        end
      end
    end
  end
end
