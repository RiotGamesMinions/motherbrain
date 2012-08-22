module MotherBrain
  module Pvpnet
    class Commands < CliBase
      class ActiveMQ < CliBase
        namespace :activemq
      end

      register ActiveMQ, 'activemq', 'activemq [COMMAND]', 'Controls for ActiveMQ only'
    end
  end
end
