module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Manages an upgrade using a {MotherBrain::Upgrade::Worker}.
    #
    class Manager
      include Celluloid

      # @see MotherBrain::Upgrade::Worker#initialize
      #
      # @return [JobTicket]
      def upgrade(environment, plugin, options = {})
        job = Job.new(:upgrade)

        Worker.new(environment, plugin, job, options).async.run

        job.ticket
      end
    end
  end
end
