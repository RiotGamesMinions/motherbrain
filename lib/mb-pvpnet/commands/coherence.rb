module MotherBrain
  module Pvpnet
    class Commands < CliBase
      # @author Jamie Winsor <jamie@vialstudios.com>
      class Coherence < CliBase
        namespace :coherence
      end

      register Coherence, 'coherence', 'coherence [COMMAND]', 'Controls for Coherence only'
    end
  end
end
