module MotherBrain
  module REST
    autoload :API, 'mb/rest/api'
    autoload :Client, 'mb/rest/client'
    autoload :Gateway, 'mb/rest/gateway'

    class << self
      # @raise [Celluloid::DeadActorError] if REST Gateway has not been started
      #
      # @return [REST::Gateway]
      def gateway
        Celluloid::Actor[:rest_gateway] or raise Celluloid::DeadActorError, "REST Gateway not running"
      end
    end
  end
end
