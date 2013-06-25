module MotherBrain::API
  require_relative 'v1'

  class Application < MB::API::Endpoint
    mount MB::API::V1
  end
end
