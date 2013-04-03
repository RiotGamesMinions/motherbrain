module MotherBrain
  module Cli
    # @author Jamie Winsor <reset@riotgames.com>
    class Base < Thor
      include Thor::Actions
      include MB::Mixin::CodedExit

      extend MB::Mixin::CodedExit

      class << self
        # Registers a SubCommand with this Cli::Base class
        #
        # @param [MB::Cli::SubCommand] klass
        def register_subcommand(klass)
          self.register(klass, klass.name, klass.usage, klass.description)
        end
      end
    end
  end
end
