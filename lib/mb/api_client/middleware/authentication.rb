module MotherBrain::ApiClient::Middleware
  class Authentication < Faraday::Middleware
    include MB::Logging

    def call(env)
      env[:request_headers] = default_headers.merge(env[:request_headers])

      log.debug { "==> performing un-authenticated motherbrain request" }
      log.debug { "request env: #{env}" }

      @app.call(env)
    end

    private

      def default_headers
        {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      end
  end
end

Faraday.register_middleware :request,
  motherbrain_auth: -> { MotherBrain::ApiClient::Middleware::Authentication }
