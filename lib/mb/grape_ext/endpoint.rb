module Grape
  class Endpoint
    alias_method :old_params, :params

    # Grape::Endpoint#params is an attr_reader that returns Grape::Request#params.
    # The latter params method returns a Hashie::Mash with Strings as keys.
    #
    # https://github.com/intridea/grape/blob/v0.6.1/lib/grape/http/request.rb#L6
    def params
      old_params.to_hash.symbolize_keys
    end
  end
end
