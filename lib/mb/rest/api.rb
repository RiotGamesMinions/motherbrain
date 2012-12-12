require 'grape'

module MotherBrain
  module REST
    # @author Jamie Winsor <jamie@vialstudios.com>
    class API < Grape::API
      format :json

      get '/config' do
        Application.config
      end

      get '/plugins' do
        Application.plugin_manager.plugins
      end
    end
  end
end
