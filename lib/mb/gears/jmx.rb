module MotherBrain
  module Gear
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
        unless jruby?
          raise ActionNotSupported, "The JMX Gear is only supported on JRuby"
        end

        JMX::Action.new(port, object_name, &block)
      end
    end

    require_relative 'jmx/action'
  end
end
