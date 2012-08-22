module MotherBrain
  module Pvpnet
    class Commands < CliBase
      # @author Jamie Winsor <jamie@vialstudios.com>
      class RTView < CliBase
        namespace :rtview
      end

      register RTView, 'rtview', 'rtview [COMMAND]', 'Controls for RTView only'
    end
  end
end
