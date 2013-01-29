module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Manages an upgrade using a {MotherBrain::Upgrade::Worker}.
    class Manager
      class << self
      # @raise [Celluloid::DeadActorError] if Upgrade Manager has not been started
      #
      # @return [Celluloid::Actor(Upgrade::Manager)]
        def instance
          MB::Application[:upgrade_manager] or raise Celluloid::DeadActorError, "upgrade manager not running"
        end
      end

      include Celluloid

      # @see MotherBrain::Upgrade::Worker#initialize
      #
      # @return [JobTicket]
      def upgrade(environment, plugin, options = {})
        job = Job.new(:upgrade)

        Worker.new(environment.freeze, plugin.freeze, job, options.freeze).async.run

        job.ticket
      end
    end
  end
end
