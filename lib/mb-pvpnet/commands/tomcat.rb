module MotherBrain
  module Pvpnet
    class Commands < CliBase
      class Tomcat < CliBase
        namespace :tomcat
      end

      register Tomcat, 'tomcat', 'tomcat [COMMAND]', 'Controls for Tomcat only'
    end
  end
end
