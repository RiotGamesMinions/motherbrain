module MotherBrain
  module Pvpnet
    class Commands < CliBase
      # @author Jamie Winsor <jamie@vialstudios.com>
      class ActiveMQ < CliBase
        namespace :activemq
      end

      register ActiveMQ, 'activemq', 'activemq [COMMAND]', 'Controls for ActiveMQ only'
    end
  end
end
