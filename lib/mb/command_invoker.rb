module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CommandInvoker
    class << self
      # @raise [Celluloid::DeadActorError] if command invoker has not been started
      #
      # @return [Celluloid::Actor(CommandInvoker)]
      def instance
        MB::Application[:command_invoker] or raise Celluloid::DeadActorError, "command invoker not running"
      end
    end

    include Celluloid
    include MB::Logging

    def initialize
      log.info { "Command Invoker starting..." }
    end
  end
end
