if MB.jruby?
  begin
    require 'jmx4r'
  rescue LoadError
    raise "A plugin that uses JMX was loaded but you do not have the 'jmx4r' gem. Run 'gem install jmx4r' and try again."
  end
end

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
        unless MB.jruby?
          raise ActionNotSupported, "The jmx action is only supported on JRuby"
        end

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
          connection = JMX::MBean.connection(host: node.public_hostname, port: port)
          mbean = JMX::MBean.find_by_name(object_name, connection: connection)
          block.call(mbean)
        end
      end
    end
  end
end
