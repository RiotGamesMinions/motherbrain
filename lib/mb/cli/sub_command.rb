module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    #
    # Generates SubCommands for Thor from motherbrain plugins or pieces of motherbrain plugins
    module SubCommand
      class << self
        # Generate a new SubCommand for Thor from a motherbrain plugin or component
        #
        # @param [MB::Plugin, MB::Component] object
        #
        # @raise [ArgumentError]
        #
        # @return [ComponentInvoker, PluginInvoker]
        def new(object)
          case object
          when MB::Plugin
            PluginInvoker.fabricate(object)
          when MB::Component
            ComponentInvoker.fabricate(object)
          else
            raise ::ArgumentError, "don't know how to fabricate a subcommand for a '#{object.class}'"
          end
        end
      end
    end
  end
end
