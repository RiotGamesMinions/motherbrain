require 'grape'
require_relative 'new_relic_instrumenter.rb'

module MotherBrain::API
  class Endpoint < Grape::API
    use NewRelicInstrumenter

    # Force inbound requests to be JSON
    def call(env)
      env['CONTENT_TYPE'] = 'application/json'
      super
    end
  end
end
