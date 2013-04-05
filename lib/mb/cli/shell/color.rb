module MotherBrain
  module Cli
    module Shell
      # @author Jamie Winsor <reset@riotgames.com>
      class Color < Thor::Shell::Color
        include MB::Cli::Shell::Ext
      end
    end
  end
end
