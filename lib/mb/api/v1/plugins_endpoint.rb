module MotherBrain::API
  class V1
    class PluginsEndpoint < MB::API::Endpoint
      helpers MB::API::Helpers
      helpers MB::Mixin::Services

      rescue_from MB::PluginNotFound do |ex|
        rack_response(ex.to_json, 404, "Content-type" => "application/json")
      end

      rescue_from Semverse::InvalidVersionFormat do |ex|
        rack_response(ex.to_json, 400, "Content-type" => "application/json")
      end

      namespace 'plugins' do
        desc "list all loaded plugins and their versions"
        get do
          plugin_manager.list
        end

        params do
          requires :name, type: String, desc: "plugin name"
        end
        namespace ':name' do
          desc "display all the versions of the given plugin"
          get do
            plugin_manager.list(name: params[:name])
          end

          namespace 'latest' do
            desc "display the latest version of the plugin of the given name"
            get do
              find_plugin!(params[:name])
            end

            desc "list of all the commands the latest plugin can do"
            get 'commands' do
              find_plugin!(params[:name]).commands
            end

            namespace 'components' do
              desc "list of all the components the latest plugin has"
              get do
                find_plugin!(params[:name]).components
              end

              desc "list of all the commands the component of the latest plugin version has"
              params do
                requires :component_id, type: String, desc: "component name"
              end
              get ':component_id/commands' do
                find_plugin!(params[:name]).component(params[:component_id])
              end
            end
          end

          params do
            requires :plugin_version, type: String, desc: "plugin version"
          end
          namespace ':plugin_version' do
            desc "display the plugin of the given name and version"
            get do
              find_plugin!(params[:name], params[:plugin_version])
            end

            desc "list of all the commands the specified plugin version can do"
            get 'commands' do
              find_plugin!(params[:name], params[:plugin_version]).commands
            end

            namespace 'components' do
              desc "list of all the components the specified plugin version has"
              get do
                find_plugin!(params[:name], params[:plugin_version]).components
              end

              desc "list of all the commands the component of the specified plugin version has"
              params do
                requires :component_id, type: String, desc: "component name"
              end
              get ':component_id/commands' do
                find_plugin!(params[:name], params[:plugin_version]).component!(params[:component_id]).commands
              end
            end
          end
        end
      end
    end
  end
end
