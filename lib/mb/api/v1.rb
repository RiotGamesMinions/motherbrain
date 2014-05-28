require 'grape-swagger'

module MotherBrain::API
  class V1 < MB::API::Endpoint
    require_relative 'v1/config_endpoint'
    require_relative 'v1/environments_endpoint'
    require_relative 'v1/jobs_endpoint'
    require_relative 'v1/plugins_endpoint'
    require_relative 'v1/chef_endpoint'
    require_relative 'v1/server_control_endpoint'

    version 'v1', using: :header, vendor: 'motherbrain'
    format :json
    default_format :json

    JSON_CONTENT_TYPE = {"Content-type" => "application/json"}

    rescue_from Grape::Exceptions::Validation do |ex|
      body = MultiJson.encode(
        status: ex.status,
        message: ex.message,
        param: ex.param
      )
      rack_response(body, ex.status, JSON_CONTENT_TYPE)
    end

    rescue_from :all do |ex|
      body = if ex.is_a?(MB::MBError)
        ex.to_json
      else
        MB.log.fatal { "an unknown error occured: #{ex}" }
        MultiJson.encode(code: -1, message: ex.message)
      end

      http_status_code = if ex.is_a?(MB::APIError)
        ex.http_status_code
      else
        500
      end

      rack_response(body, http_status_code, JSON_CONTENT_TYPE)
    end

    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
      header.delete('Transfer-Encoding')

      server_control_endpoint = false
      MB::API::V1::ServerControlEndpoint.endpoints.each do |endpoint|
        endpoint.routes.each do |route|
          if request.path =~ route.route_compiled
            server_control_endpoint = true
            break
          end
        end
      end
      
      raise MB::ApplicationPaused.new if MB::Application.paused? && !server_control_endpoint
    end

    mount V1::ConfigEndpoint
    mount V1::JobsEndpoint
    mount V1::EnvironmentsEndpoint
    mount V1::PluginsEndpoint
    mount V1::ChefEndpoint
    mount V1::ServerControlEndpoint
    add_swagger_documentation

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
