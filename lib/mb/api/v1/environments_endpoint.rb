module MotherBrain::API
  class V1
    class EnvironmentsEndpoint < MB::API::Endpoint
      helpers MB::API::Helpers

      rescue_from MB::NoBootstrapRoutine do |ex|
        rack_response(ex.to_json, 405, "Content-type" => "application/json")
      end

      rescue_from MB::InvalidProvisionManifest, MB::InvalidBootstrapManifest do |ex|
        rack_response(ex.to_json, 400, "Content-type" => "application/json")
      end

      namespace 'environments' do
        desc "list all of the environments"
        get do
          environment_manager.list
        end

        params do
          requires :environment_id, type: String, desc: "environment name"
        end
        namespace ':environment_id' do
          desc "destroy a provisioned environment"
          delete do
            provisioner.async_destroy(params[:environment_id])
          end

          desc "create (provision) a new cluster of nodes"
          params do
            requires :manifest, type: Hash, desc: "a Hash representation of the node group to create"
            group :plugin do
              requires :name, type: String, desc: "name of the plugin to use"
              optional :version, sem_ver: true, desc: "version of the plugin to use"
            end
            optional :chef_version, type: String, desc: "version of Chef to install on the node(s)"
            optional :component_versions, type: Hash, desc: "component versions to set with default attributes"
            optional :cookbook_versions, type: Hash, desc: "cookbook versions to set on the environment"
            optional :environment_attributes, type: Hash, desc: "additional attributes to set on the environment"
            optional :skip_bootstrap, type: Boolean, desc: "skip automatic bootstrapping of the created environment"
            optional :force, type: Boolean, desc: "force provisioning nodes to the environment even if the environment is locked"
          end
          post do
            plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
            manifest = Provisioner::Manifest.new(params[:manifest])
            manifest.validate!(plugin)

            provisioner.async_provision(
              params[:environment_id].freeze,
              manifest.freeze,
              plugin.freeze,
              params.except(:environment_id, :manifest, :plugin).freeze
            )
          end

          desc "update (bootstrap) an existing cluster of nodes"
          params do
            requires :manifest, desc: "a Hash representation of the node group to update"
            group :plugin do
              requires :name, type: String, desc: "name of the plugin to use"
              optional :version, sem_ver: true, desc: "version of the plugin to use"
            end
            optional :chef_version, type: String, desc: "version of Chef to install on the node(s)"
            optional :component_versions, type: Hash, desc: "component versions to set with default attributes"
            optional :cookbook_versions, type: Hash, desc: "cookbook versions to set on the environment"
            optional :environment_attributes, type: Hash, desc: "additional attributes to set on the environment"
            optional :force, type: Boolean
            optional :hints
          end
          put do
            plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
            manifest = Bootstrap::Manifest.new(params[:manifest])
            manifest.validate!(plugin)

            bootstrapper.async_bootstrap(
              params[:environment_id].freeze,
              manifest.freeze,
              plugin.freeze,
              params.slice(:chef_version, :component_versions, :cookbook_versions, :environment_attributes, :force, :bootstrap_proxy, :hints).freeze
            )
          end

          desc "lock an environment"
          post 'lock' do
            lock_manager.async_lock(params[:environment_id])
          end

          desc "unlock an environment"
          delete 'lock' do
            lock_manager.async_unlock(params[:environment_id])
          end

          desc "configure an existing environment cluster"
          params do
            requires :attributes, type: Hash, desc: "a hash of attributes to set on the environment"
            optional :force, type: Boolean, desc: "force configure even if the environment is locked"
          end
          post 'configure' do
            environment_manager.async_configure(params[:environment_id], params.slice(:attributes, :force))
          end

          desc "upgrade an environment to the specified versions"
          params do
            group :plugin do
              requires :name, type: String, desc: "name of the plugin to use"
              optional :version, sem_ver: true, desc: "version of the plugin to use"
            end
            optional :component_versions, type: Hash, desc: "the component versions to set with default attributes"
            optional :cookbook_versions, type: Hash, desc: "the cookbook versions to set on the environment"
            optional :environment_attributes, type: Hash, desc: "any additional attributes to set on the environment"
            optional :force, type: Boolean, desc: "force upgrade even if the environment is locked"
          end
          post 'upgrade' do
            options = params.slice(:component_versions, :cookbook_versions, :environment_attributes, :force)
            plugin  = plugin_manager.find(params[:plugin][:name], params[:plugin][:version])

            upgrade_manager.async_upgrade(params[:environment_id], plugin, options)
          end

          params do
            requires :plugin_id, type: String, desc: "plugin name"
          end
          namespace 'commands/:plugin_id' do
            desc "list of commands the plugin associated with the environment supports"
            get do
              plugin_manager.for_environment(params[:plugin_id], params[:environment_id]).commands
            end

            desc "invoke a plugin level command on the target environment"
            params do
              requires :command_id, type: String, desc: "command name"
              optional :arguments, type: Array, desc: "optional array of arguments for the command"
              optional :force, type: Boolean, desc: "force command an environment even if it is locked"
            end
            post ':command_id' do
              command_invoker.async_invoke(params[:command_id],
                plugin: params[:plugin_id],
                component: params[:component_id],
                environment: params[:environment_id],
                arguments: params[:arguments],
                force: params[:force]
              )
            end

            desc "list of commands the component of the plugin associated with the environment supports"
            params do
              requires :component_id, type: String, desc: "plugin component name"
            end
            get ':component_id' do
              plugin = plugin_manager.for_environment(params[:plugin_id], params[:environment_id])
              plugin.component!(params[:component_id]).commands
            end

            desc "invoke a plugin component level command on the target environment"
            params do
              requires :component_id, type: String, desc: "plugin component name"
              requires :command_id, type: String, desc: "command name"
              optional :arguments, type: Array, desc: "optional array of arguments for the command"
            end
            post ':component_id/:command_id' do
              command_invoker.invoke_component(
                params[:plugin_id],
                params[:component_id],
                params[:command_id],
                params[:environment_id],
                params.slice(:arguments)
              )
            end
          end
        end
      end
    end
  end
end
