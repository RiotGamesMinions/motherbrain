module MotherBrain
  module Gear
    # @author Jesse Howarth <jhowarth@riotgames.com>
    class JMX < Gear::Base
      register_gear :jmx

      # @param [Fixnum] port
      #   the port to connect over
      # @param [String] object_name
      #   the name of the jmx object
      #
      # @raise [ActionNotSupported] if not running JRuby
      # @raise [ArgumentError]
      def action(port, object_name, &block)
        JMX::Action.new(port, object_name, &block)
      end
    end

    require_relative 'gears/jmx'
  end
end
