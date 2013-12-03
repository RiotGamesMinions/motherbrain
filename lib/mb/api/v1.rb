module MotherBrain::API
  class V1 < MB::API::Endpoint
    require_relative 'v1/config_endpoint'
    require_relative 'v1/environments_endpoint'
    require_relative 'v1/jobs_endpoint'
    require_relative 'v1/plugins_endpoint'

    version 'v1', using: :header, vendor: 'motherbrain'
    format :json
    default_format :json

    rescue_from Grape::Exceptions::Validation do |e|
      body = MultiJson.encode(
        status: e.status,
        message: e.message,
        param: e.param
      )
      rack_response(body, e.status, "Content-type" => "application/json")
    end

    rescue_from :all do |ex|
      body = if ex.is_a?(MB::MBError)
        ex.to_json
      else
        MB.log.fatal { "an unknown error occured: #{ex}" }
        MultiJson.encode(code: -1, message: ex.message)
      end

      rack_response(body, 500, "Content-type" => "application/json")
    end

    mount V1::ConfigEndpoint
    mount V1::JobsEndpoint
    mount V1::EnvironmentsEndpoint
    mount V1::PluginsEndpoint

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
