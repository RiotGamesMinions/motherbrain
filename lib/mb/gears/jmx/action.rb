begin
  require 'jmx4r'
rescue LoadError; end

module MotherBrain
  module Gear
    class JMX
      # @api private
      class Action
        attr_reader :port
        attr_reader :object_name
        attr_reader :block

        # @param [Fixnum] port the port to connect over
        # @param [String] object_name the name of the jmx object
        #
        # @raise [ArgumentError]
        def initialize(port, object_name, &block)
          unless block_given? && block.arity == 1
            raise ArgumentError, "block with one argument required to run JMX actions"
          end

          @port        = port
          @object_name = object_name
          @block       = block
        end

        # Run this action on the specified nodes.
        #
        # @param [MB::Job] job
        #   a job to update with status
        # @param [String] environment
        #   the environment this command is being run on
        # @param [Array<Ridley::Node>] nodes
        #   the nodes to run this action on
        def run(job, environment, nodes)
          nodes.each do |node|
            connection = ::JMX::MBean.connection(host: node.public_hostname, port: port)
            mbean      = ::JMX::MBean.find_by_name(object_name, connection: connection)
            block.call(mbean)
          end
        end
      end
    end
  end
end
