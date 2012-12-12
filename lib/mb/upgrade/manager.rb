module MotherBrain
  module Upgrade
    class Manager
      include Celluloid
      include ActorUtil

      def upgrade(environment, plugin, options)
        Worker.new(environment, plugin, options).run
      end
    end
  end
end
