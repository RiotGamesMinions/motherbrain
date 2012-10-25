require 'jmx4r'

module MotherBrain
  module Action
    # @author Jesse Howarth <jhowarth@riotgames.com>
    class Jmx
      attr_reader :port
      attr_reader :object_name
      attr_reader :block

      # @param [Fixnum] port the port to connect over
      # @param [String] object_name the name of the jmx object
      def initialize(port, object_name, &block)
        unless block_given? && block.arity == 1
          raise ArgumentError, "block with one argument required for jmx action"
        end

        @port = port
        @object_name = object_name
        @block = block
      end

      # Run this action on the specified nodes.
      #
      # @param [Array<Ridley::Node>] nodes the nodes to run this action on
      def run(nodes)
        nodes.each do |node|
          connection = JMX::MBean.connection(host: node.automatic[:cloud][:public_hostname], port: port)
          mbean = JMX::MBean.find_by_name(object_name, connection: connection)
          block.call(mbean)
        end
      end
    end
  end
end
