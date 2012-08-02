require 'mb/cli_base'

module MotherBrain
  module Pvpnet
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Commands < CliBase
      namespace :pvpnet

      desc "version", "Display version information"
      def version
        MB.ui.say "MotherBrain: PvPnet (#{MB::Pvpnet::VERSION})"
      end
    end

    MB::Cli.register Commands, 'pvpnet', 'pvpnet [COMMAND]', 'Cluster controls for pvpnet platform core'
  end
end
