require 'grape'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class API < Grape::API
      class << self
        def testing?
          ENV['RUBY_ENV'] == 'test'
        end
      end

      format :json

      rescue_from :all do |e|
        body = e.is_a?(MB::MBError) ? e.to_json : MultiJson.encode(code: -1, message: "an unknown error occured")
        rack_response(body, 500, "Content-type" => "application/json")
      end

      get '/config' do
        Application.config
      end

      get '/plugins' do
        Application.plugin_manager.plugins
      end

      if testing?
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
