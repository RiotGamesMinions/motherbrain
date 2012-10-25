require 'jmx4r'

module MotherBrain
  module Action
    class Jmx
      attr_reader :port
      attr_reader :object_name
      attr_reader :block

      def initialize(port, object_name, &block)
        unless block_given? && block.arity == 1
          raise ArgumentError, "block with one argument required for jmx action"
        end

        @port = port
        @object_name = object_name
        @block = block
      end

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
