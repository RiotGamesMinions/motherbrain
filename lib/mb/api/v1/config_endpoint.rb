module MotherBrain::API
  class V1
    class ConfigEndpoint < MB::API::Endpoint
      desc "display the loaded configuration"
      get 'config' do
        config_manager.config
      end
    end
  end
end
