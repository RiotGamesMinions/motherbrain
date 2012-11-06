module MotherBrain
  class ClusterBootstrapper
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

      # @return [String]
      attr_reader :group_id
      # @return [Array<String>]
      attr_reader :nodes
      # @return [Hash]
      attr_reader :options

      # @param [String] group_id
      #   a string containing a group_id for the nodes being bootstrapped
      #     'activemq::master'
      #     'mysql::slave'
      # @param [Array<String>] nodes
      #   an array of hostnames or ipaddresses to bootstrap
      #     [ '33.33.33.10', 'reset.riotgames.com' ]
      # @param [Hash] options
      #   hash of options that will be passed to Ridley::Bootstrapper#new
      def initialize(group_id, nodes, options = {})
        @group_id = group_id
        @nodes    = nodes
        @options  = options
      end

      # @return [Array]
      def run
        if nodes && nodes.any?
          MB.log.debug "Bootstrapping group: '#{group_id}' [ #{nodes.join(', ')} ] with options: '#{options}'"
          Ridley::Bootstrapper.new(nodes, options).run
        else
          MB.log.debug "No nodes in group: '#{group_id}'. Skipping bootstrap task"
          [ :ok, [] ]
        end
      end
    end
  end
end
