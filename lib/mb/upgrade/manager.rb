module MotherBrain
  module Upgrade
    # @author Justin Campbell <justin@justincampbell.me>
    #
    # Manages an upgrade using a {MotherBrain::Upgrade::Worker}.
    #
    class Manager
      include Celluloid
      include ActorUtil

      # @param [String] environment
      #
      # @param [MotherBrain::Plugin] plugin
      #
      # @param [Hash] options # TODO: add options documentation
      #
      def upgrade(environment, plugin, options = {})
        Worker.new(environment, plugin, options).run
      end
    end
  end
end
