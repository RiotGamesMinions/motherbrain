module MotherBrain::API
  class V1
    class ConfigEndpoint < MB::API::Endpoint
      helpers MB::Mixin::Services

      desc "display the loaded configuration"
      get 'config' do
        config_manager.config
      end
    end
  end
end
