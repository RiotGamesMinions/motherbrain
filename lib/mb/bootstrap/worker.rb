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
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to use in the first Chef run
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
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
        MB.log.debug "Bootstrapping group: '#{group_id}' [ #{nodes.join(', ')} ] with options: '#{options}'"
        unless nodes && nodes.any?
          MB.log.debug "No nodes in group: '#{group_id}'. Skipping..."
          return [ :ok, [] ]
        end

        full_nodes, partial_nodes = bootstrap_type_filter

        [
          self.future.full_bootstrap(full_nodes, options),
          self.future.partial_bootstrap(partial_nodes, options.slice(:attributes, :run_list))
        ].map(&:value).flatten
      end

      # Split the nodes to bootstrap into two groups. One group of nodes who do not have a client
      # present on the Chef Server and require a full bootstrap and another group of nodes who
      # have a client and require a partial bootstrap
      #
      # @example splitting nodes into two groups based on chef client presence
      #   self.nodes => [
      #     "no-client1.riotgames.com",
      #     "no-client2.riotgames.com",
      #     'has-client.riotgames.com"'
      #   ]
      #
      #   self.bootstrap_type_filter => [
      #     [ "no-client1.riotgames.com", "no-client2.riotgames.com" ],
      #     [ "has-client.riotgames.com" ]
      #   ]
      #
      # @return [Array]
      def bootstrap_type_filter
        client_names  = chef_conn.client.all.map(&:name)
        full_nodes    = Array.new
        partial_nodes = Array.new

        self.nodes.each do |node|
          if client_names.include?(node)
            partial_nodes << node
          else
            full_nodes << node
          end
        end

        [ full_nodes, partial_nodes ]
      end

      protected

        def full_bootstrap(l_nodes, options)
          chef_conn.node.bootstrap(l_nodes, options)
        end

        def partial_bootstrap(l_nodes, options)
          l_nodes.collect do |node|
            Celluloid::Future.new {
              MB.log.debug "Node (#{node}) is already registered with Chef: performing a partial bootstrap"
              updated_node = chef_conn.node.merge_data(node, options)
              updated_node.chef_client
            }
          end.map(&:value)
        end
    end
  end
end
