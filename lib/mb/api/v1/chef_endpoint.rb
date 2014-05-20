module MotherBrain::API
  class V1
    class ChefEndpoint < MB::API::Endpoint
      helpers MB::API::Helpers

      rescue_from MB::OmnibusUpgradeError do |ex|
        rack_response(ex.to_json, 400, "Content-type" => "application/json")
      end

      namespace 'chef' do

        desc "Remove Chef from node and purge it's data from the Chef server"
        params do
          requires :hostname, type: String, desc: "the hostname of the node to purge"
          optional :skip_chef, type: Boolean, desc: "Skip removing the Chef installation from the node"
        end
        post 'purge' do
          node_querier.async_purge(params[:hostname], params.slice(:skip_chef).freeze)
        end

        desc "Upgrades the provided node and an environment of node's Omnibus Chef installation"
        params do
          requires :version, type: String, desc: "the version of omnibus to upgrade to"
          optional :environment_id, type: String, desc: "an environment to upgrade"
          optional :host, type: String, desc: "a host to upgrade"
          optional :prerelease, type: Boolean, desc: "boolean to use a prerelease version of Chef"
          optional :direct_url, type: String, desc: "a direct URL to a Omnibus binary file"
        end
        post 'upgrade' do
          nodes = nil
          host = params[:host]
          environment_id = params[:environment_id]

          raise MB::OmnibusUpgradeError.new("Need to provide one of :environment_id or :host") if host.nil? && environment_id.nil?
          raise MB::OmnibusUpgradeError.new("Both :environment_id and :host were provided") if !host.nil? && !environment_id.nil?

          if host
            node_object = Ridley::NodeObject.new(host, automatic: { fqdn: host })
            nodes = [node_object]
          elsif environment_id
            nodes = environment_manager.nodes_for_environment(params[:environment_id])
          end
          node_querier.async_upgrade_omnibus(params[:version], nodes, params.slice(:prerelease, :direct_url).freeze)
        end
      end
    end
  end
end
