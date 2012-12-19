require 'grape'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class API < Grape::API
      helpers do
        include MB::Logging
      end

      format :json

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
      get '/config' do
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
          JobManager.instance.find(params[:id])
        end
      end

      resource :plugins do
        desc "list all loaded plugins and their versions"
        get do
          Application.plugin_manager.plugins
        end
      end

      if MB.testing?
        get '/mb_error' do
          raise MB::InternalError, "a nice error message"
        end

        get '/unknown_error' do
          raise ::ArgumentError, "hidden error message"
        end
      end
    end
  end
end
