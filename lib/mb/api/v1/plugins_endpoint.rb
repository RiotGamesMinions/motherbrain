module MotherBrain::API
  class V1
    class PluginsEndpoint < MB::API::Endpoint
      namespace 'plugins' do
        desc "list all loaded plugins and their versions"
        get do
          plugin_manager.list
        end

        params do
          requires :plugin_id, type: String, desc: "plugin name"
        end
        namespace ':plugin_id' do
          desc "display all the versions of the given plugin"
          get do
            plugin_manager.list(name: params[:plugin_id])
          end

          namespace 'latest' do
            desc "display the latest version of the plugin of the given name"
            get do
              find_plugin!(params[:plugin_id])
            end

            desc "list of all the commands the latest plugin can do"
            get 'commands' do
              find_plugin!(params[:plugin_id]).commands
            end

            namespace 'components' do
              desc "list of all the components the latest plugin has"
              get do
                find_plugin!(params[:plugin_id]).components
              end

              desc "list of all the commands the component of the latest plugin version has"
              params do
                requires :component_id, type: String, desc: "component name"
              end
              get ':component_id/commands' do
                find_plugin!(params[:plugin_id]).component(params[:component_id])
              end
            end
          end

          params do
            requires :version, sem_ver: true
          end
          namespace ':version' do
            desc "display the plugin of the given name and version"
            get do
              find_plugin!(params[:plugin_id], params[:version])
            end

            desc "list of all the commands the specified plugin version can do"
            get 'commands' do
              find_plugin!(params[:plugin_id], params[:version]).commands
            end

            namespace 'components' do
              desc "list of all the components the specified plugin version has"
              get do
                find_plugin!(params[:plugin_id], params[:version]).components
              end

              desc "list of all the commands the component of the specified plugin version has"
              params do
                requires :component_id, type: String, desc: "component name"
              end
              get ':component_id/commands' do
                find_plugin!(params[:plugin_id], params[:version]).component!(params[:component_id]).commands
              end
            end
          end
        end
      end
    end
  end
end
