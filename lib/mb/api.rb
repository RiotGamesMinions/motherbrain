require 'grape'
require 'mb/api_validators'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Api < Grape::API
    helpers MB::Logging
    helpers MB::ApiHelpers

    format :json

    rescue_from Grape::Exceptions::ValidationError do |e|
      body = {
        status: e.status,
        message: e.message,
        param: e.param
      }
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
    get :config do
      Application.config
    end

    resource :jobs do
      desc "list all jobs (completed and active)"
      get do
        JobManager.instance.list
      end

      desc "list all active jobs"
      get :active do
        JobManager.instance.active
      end

      desc "find and return the Job with the given ID"
      params do
        requires :id, type: String, desc: "job id"
      end
      get ':id' do
        find_job!(params[:id])
      end
    end

    resource :environments do
      desc "destroy a provisioned environment"
      params do
        requires :id, type: String, desc: "environment name"
      end
      delete ':id' do
        provisioner.destroy(params[:id])
      end

      desc "create (provision) a new cluster of nodes"
      params do
        requires :id, type: String, desc: "environment name"
        requires :manifest, desc: "a Hash representation of the node group to create"
        group :plugin do
          requires :name, type: String, desc: "name of the plugin to use"
          optional :version, sem_ver: true, desc: "version of the plugin to use"
        end
      end
      post ':id' do
        plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
        manifest = Provisioner::Manifest.from_hash(params[:manifest].to_hash)
        manifest.validate!(plugin)

        provisioner.provision(
          params[:id].freeze,
          manifest.freeze,
          plugin.freeze
        )
      end

      desc "update (bootstrap) an existing cluster of nodes"
      params do
        requires :id, type: String, desc: "environment name"
        requires :manifest, desc: "a Hash representation of the node group to update"
        group :plugin do
          requires :name, type: String, desc: "name of the plugin to use"
          optional :version, sem_ver: true, desc: "version of the plugin to use"
        end
        optional :force, type: Boolean
        optional :hints
      end
      put ':id' do
        plugin   = find_plugin!(params[:plugin][:name], params[:plugin][:version])
        manifest = Bootstrap::Manifest.from_hash(params[:manifest].to_hash)
        manifest.validate!(plugin)

        bootstrapper.bootstrap(
          params[:id].freeze,
          manifest.freeze,
          plugin.freeze,
          params.slice(:force, :bootstrap_proxy, :hints).freeze
        )
      end
    end

    resource :plugins do
      desc "list all loaded plugins and their versions"
      get do
        plugin_manager.plugins
      end

      desc "display all the versions of the given plugin"
      params do
        requires :name, type: String, desc: "plugin name"
      end
      get ':name' do
        list_plugins!(params[:name])
      end

      desc "display the latest version of the plugin of the given name"
      params do
        requires :name, type: String, desc: "plugin name"
      end
      get ':name/latest' do
        find_plugin!(params[:name])
      end

      desc "display the plugin of the given name and version"
      params do
        requires :name, type: String, desc: "plugin name"
        requires :version, sem_ver: true
      end
      get ':name/:version' do
        find_plugin!(params[:name], params[:version])
      end
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
