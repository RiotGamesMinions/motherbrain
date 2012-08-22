module MotherBrain
  module Pvpnet
    class Commands < CliBase
      # @author Jamie Winsor <jamie@vialstudios.com>
      class Tomcat < CliBase
        namespace :tomcat
      end

      register Tomcat, 'tomcat', 'tomcat [COMMAND]', 'Controls for Tomcat only'
    end
  end
end
