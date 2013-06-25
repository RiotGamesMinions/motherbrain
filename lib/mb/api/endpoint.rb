require 'grape'

module MotherBrain::API
  class Endpoint < Grape::API
    # Force inbound requests to be JSON
    def call(env)
      env['CONTENT_TYPE'] = 'application/json'
      super
    end
  end
end
