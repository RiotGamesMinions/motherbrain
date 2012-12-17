module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Manages an upgrade using a {MotherBrain::Upgrade::Worker}.
    #
    class Manager
      include Celluloid

      # @see MotherBrain::Upgrade::Worker#initialize
      def upgrade(environment, plugin, options = {})
        Worker.new(environment, plugin, options).run
      end
    end
  end
end
