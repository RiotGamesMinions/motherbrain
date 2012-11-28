module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

      # @return [Ridley::Connection]
      attr_reader :chef_conn
      # @return [String]
      attr_reader :group_id
      # @return [Array<String>]
      attr_reader :nodes
      # @return [Hash]
      attr_reader :options

      # @param [Ridley::Connection] chef_conn
      #   connection for Chef
      # @param [String] group_id
      #   a string containing a group_id for the nodes being bootstrapped
      #     'activemq::master'
      #     'mysql::slave'
      # @param [Array<String>] nodes
      #   an array of hostnames or ipaddresses to bootstrap
      #     [ '33.33.33.10', 'reset.riotgames.com' ]
      # @option options [String] :environment ('_default')
      # @option options [Hash] :attributes
      #   a hash of attributes to use in the first Chef run (default: Hash.new)
      # @option options [Array] :run_list
      #   an initial run list to bootstrap with (default: Array.new)
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      def initialize(chef_conn, group_id, nodes, options = {})
        @chef_conn = chef_conn
        @group_id  = group_id
        @nodes     = nodes
        @options   = options
      end

      # @return [Array]
      def run
        if nodes && nodes.any?
          MB.log.debug "Bootstrapping group: '#{group_id}' [ #{nodes.join(', ')} ] with options: '#{options}'"
          chef_conn.node.bootstrap(nodes, options)
        else
          MB.log.debug "No nodes in group: '#{group_id}'. Skipping bootstrap task"
          [ :ok, [] ]
        end
      end
    end
  end
end
