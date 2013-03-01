require 'grape'
require 'mb/api_validators'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Api < Grape::API
    helpers MB::Logging
    helpers MB::ApiHelpers
    helpers MB::Mixin::Services

    format :json

    rescue_from Grape::Exceptions::Validation do |e|
      body = MultiJson.encode(
        status: e.status,
        message: e.message,
        param: e.param
      )
      rack_response(body, e.status, "Content-type" => "application/json")
    end

    rescue_from PluginNotFound, JobNotFound do |ex|
      rack_response(ex.to_json, 404, "Content-type" => "application/json")
    end

    rescue_from NoBootstrapRoutine do |ex|
      rack_response(ex.to_json, 405, "Content-type" => "application/json")
    end

    rescue_from InvalidProvisionManifest, InvalidBootstrapManifest do |ex|
      rack_response(ex.to_json, 400, "Content-type" => "application/json")
    end

    rescue_from :all do |ex|
      body = if ex.is_a?(MB::MBError)
        ex.to_json
      else
        MB.log.fatal { "an unknown error occured: #{ex}" }
        MultiJson.encode(code: -1, message: "an unknown error occured")
      end

      rack_response(body, 500, "Content-type" => "application/json")
    end

    desc "display the loaded configuration"
    get 'config' do
      Application.config
    end

    namespace 'jobs' do
      desc "list all jobs (completed and active)"
      get do
        JobManager.instance.list
      end

      desc "list all active jobs"
      get 'active' do
        JobManager.instance.active
      end

      desc "find and return the Job with the given ID"
      params do
        requires :job_id, type: String, desc: "job id"
      end
      get ':job_id' do
        find_job!(params[:job_id])
      end
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
          provisioner.destroy(params[:environment_id])
        end

        desc "create (provision) a new cluster of nodes"
        params do
          requires :manifest, type: Hash, desc: "a Hash representation of the node group to create"
          group :plugin do
            requires :name, type: String, desc: "name of the plugin to use"
            optional :version, sem_ver: true, desc: "version of the plugin to use"
          end
          optional :component_versions, type: Hash, desc: "component versions to set with override attributes"
          optional :cookbook_versions, type: Hash, desc: "cookbook versions to set on the environment"
          optional :environment_attributes, type: Hash, desc: "additional attributes to set on the environment"
          optional :skip_bootstrap, type: Boolean, desc: "skip automatic bootstrapping of the created environment"
          optional :force, type: Boolean, desc: "force provisioning nodes to the environment even if the environment is locked"
        end
        post do
          plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
          manifest = Provisioner::Manifest.new(params[:manifest])
          manifest.validate!(plugin)

          provisioner.provision(
            params[:environment_id].freeze,
            manifest.freeze,
            plugin.freeze,
            params.exclude(:environment_id, :manifest, :plugin).freeze
          )
        end

        desc "update (bootstrap) an existing cluster of nodes"
        params do
          requires :manifest, desc: "a Hash representation of the node group to update"
          group :plugin do
            requires :name, type: String, desc: "name of the plugin to use"
            optional :version, sem_ver: true, desc: "version of the plugin to use"
          end
          optional :component_versions, type: Hash, desc: "component versions to set with override attributes"
          optional :cookbook_versions, type: Hash, desc: "cookbook versions to set on the environment"
          optional :environment_attributes, type: Hash, desc: "additional attributes to set on the environment"
          optional :force, type: Boolean
          optional :hints
        end
        put do
          plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
          manifest = Bootstrap::Manifest.new(params[:manifest])
          manifest.validate!(plugin)

          bootstrapper.bootstrap(
            params[:environment_id].freeze,
            manifest.freeze,
            plugin.freeze,
            params.slice(:component_versions, :cookbook_versions, :environment_attributes, :force, :bootstrap_proxy, :hints).freeze
          )
        end

        desc "lock an environment"
        post 'lock' do
          lock_manager.lock(params[:environment_id])
        end

        desc "unlock an environment"
        delete 'lock' do
          lock_manager.unlock(params[:environment_id])
        end

        desc "configure an existing environment cluster"
        params do
          requires :attributes, type: Hash, desc: "a hash of attributes to set on the environment"
          optional :force, type: Boolean, desc: "force configure even if the environment is locked"
        end
        post 'configure' do
          environment_manager.configure(params[:environment_id], params.slice(:attributes, :force))
        end

        desc "upgrade an environment to the specified versions"
        params do
          group :plugin do
            requires :name, type: String, desc: "name of the plugin to use"
            optional :version, sem_ver: true, desc: "version of the plugin to use"
          end
          optional :component_versions, type: Hash, desc: "the component versions to set with override attributes"
          optional :cookbook_versions, type: Hash, desc: "the cookbook versions to set on the environment"
          optional :environment_attributes, type: Hash, desc: "any additional attributes to set on the environment"
          optional :force, type: Boolean, desc: "force upgrade even if the environment is locked"
        end
        post 'upgrade' do
          options = params.slice(:component_versions, :cookbook_versions, :environment_attributes, :force)
          plugin  = plugin_manager.find(params[:plugin][:name], params[:plugin][:version])

          upgrade_manager.upgrade(params[:environment_id], plugin, options)
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
          end
          post ':command_id' do
            command_invoker.invoke_plugin(
              params[:plugin_id],
              params[:command_id],
              params[:environment_id],
              params.slice(:arguments)
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
          plugin_manager.versions(params[:plugin_id])
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

    # Force inbound requests to be JSON
    def call(env)
      env['CONTENT_TYPE'] = 'application/json'
      super
    end

    if MB.testing?
      get :mb_error do
        raise MB::InternalError, "a nice error message"
      end

      get :unknown_error do
        raise ::ArgumentError, "hidden error message"
      end
    end
  end
end
