module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # Generates SubCommands for Thor from motherbrain plugins or pieces of motherbrain plugins
    module SubCommand
      autoload :Base, 'mb/cli/sub_command/base'
      autoload :Component, 'mb/cli/sub_command/component'
      autoload :Plugin, 'mb/cli/sub_command/plugin'

      class << self
        # Generate a new SubCommand for Thor from a motherbrain plugin or component
        #
        # @param [MB::Plugin, MB::Component] object
        # @param [String] environment
        #
        # @raise [ArgumentError]
        #
        # @return [SubCommand::Plugin, SubCommand::Component]
        def new(object, environment)
          case object
          when MB::Plugin
            SubCommand::Plugin.fabricate(object, environment)
          when MB::Component
            SubCommand::Component.fabricate(object, environment)
          else
            raise ::ArgumentError, "don't know how to fabricate a subcommand for a '#{object.class}'"
          end
        end
      end
    end
  end
end
