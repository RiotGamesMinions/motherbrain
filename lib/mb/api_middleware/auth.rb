module MotherBrain
  module ApiMiddleware
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Auth < Grape::Middleware::Base
      def before
        if ENV['X-Authorization'].nil?
          throw :error,
            status: 403,
            message: "Please authenticate.",
            headers: {
              "WWW-Authenticate" => "Token realm='http://example.com'"
            }
        end

        response = AuthManager.instance.authenticate(ENV['X-Authorization'])

        case response
        when :authorized
          return true
        when :unauthorized
          throw :error, status: 401, message: "API authorization failed."
        when :rate_limited
          throw :error, status: 401, message: "API request limit reached."
        else
          raise InternalError, "Unknown response from AuthManager#authenticate: #{response}"
        end
      end
    end
  end
end
