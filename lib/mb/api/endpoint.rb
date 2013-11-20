require 'grape'

module MotherBrain::API
  class Endpoint < Grape::API
    include MB::Logging
  end
end

module Grape
  class Endpoint
    alias_method :old_params, :params
    def params
      old_params.to_hash.symbolize_keys
    end
  end
end
