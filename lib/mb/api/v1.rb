require 'mb/api_validators'

module MotherBrain::API
  class V1 < MB::API::Endpoint
    require_relative 'v1/config_endpoint'
    require_relative 'v1/environments_endpoint'
    require_relative 'v1/jobs_endpoint'
    require_relative 'v1/plugins_endpoint'

    version 'v1', using: :header, vendor: 'motherbrain'
    format :json

    helpers MB::Logging
    helpers MB::ApiHelpers
    helpers MB::Mixin::Services

    mount V1::ConfigEndpoint
    mount V1::JobsEndpoint
    mount V1::EnvironmentsEndpoint
    mount V1::PluginsEndpoint

    rescue_from Grape::Exceptions::Validation do |e|
      body = MultiJson.encode(
        status: e.status,
        message: e.message,
        param: e.param
      )
      rack_response(body, e.status, "Content-type" => "application/json")
    end

    rescue_from MB::PluginNotFound, MB::JobNotFound do |ex|
      rack_response(ex.to_json, 404, "Content-type" => "application/json")
    end

    rescue_from MB::NoBootstrapRoutine do |ex|
      rack_response(ex.to_json, 405, "Content-type" => "application/json")
    end

    rescue_from MB::InvalidProvisionManifest, MB::InvalidBootstrapManifest do |ex|
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
