module MotherBrain
  module ApiMiddleware
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Auth < Grape::Middleware::Base
      def before
        throw :error, status: 401, message: "API authorization failed."
      end
    end
  end
end
