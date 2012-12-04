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
      attr_reader :ssh_options

      attr_reader :node_querier

      # @param [String] group_id
      #   a string containing a group_id for the nodes being bootstrapped
      #     'activemq::master'
      #     'mysql::slave'
      # @param [Array<String>] nodes
      #   an array of hostnames or ipaddresses to bootstrap
      #     [ '33.33.33.10', 'reset.riotgames.com' ]
      # @param [Ridley::Connection] chef_conn
      #   connection to a Chef Server
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
      def initialize(group_id, nodes, chef_conn, options = {})
        @group_id     = group_id
        @nodes        = nodes
        @chef_conn    = chef_conn
        @options      = options

        @node_querier = NodeQuerier.supervise(chef_conn).actors.first
      end

      # @example
      #   worker.run => [
      #     #<Ridley::SSH::ResponseSet @failures=[], @successes=[]>,
      #     #<Ridley::SSH::ResponseSet @failures=[], @successes=[]>
      #   ]
      #
      # @return [Array<Ridley::SSH::ResponseSet]
      def run
        MB.log.info "Bootstrapping group: '#{group_id}' [ #{nodes.join(', ')} ] with options: '#{options}'"
        unless nodes && nodes.any?
          MB.log.info "No nodes in group: '#{group_id}'. Skipping..."
          return [ :ok, [] ]
        end

        full_nodes    = Array.new
        partial_nodes = Array.new
        full_nodes, partial_nodes = bootstrap_type_filter

        [].tap do |futures|
          unless full_nodes.empty?
            futures << Celluloid::Future.new {
              full_bootstrap(full_nodes, options)
            }
          end

          unless partial_nodes.empty?
            futures << Celluloid::Future.new {
              partial_bootstrap(partial_nodes, options.slice(:attributes, :run_list))
            }
          end
        end.map(&:value).flatten.inject(:merge)
      end

      # Split the nodes to bootstrap into two groups. One group of nodes who do not have a client
      # present on the Chef Server and require a full bootstrap and another group of nodes who
      # have a client and require a partial bootstrap.
      #
      # The first group of nodes will be returned as an array of hostnames to bootstrap.
      #
      # The second group of nodes will be returned as an array of Hashes containing a hostname and
      # the node_name for the machine. The node_name may defer from the hostname depending on how
      # the target node was initially bootstrapped.
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
      #     [ 
      #       {
      #         hostname: "has-client.riotgames.com",
      #         node_name: "has-client.internal"
      #       }
      #     ]
      #   ]
      #
      # @return [Array]
      def bootstrap_type_filter
        known_nodes = Celluloid::Future.new {
          chef_conn.node.all.map { |node| node.name.to_s }
        }

        node_list = self.nodes.collect do |node|
          {
            hostname: node,
            node_name: node_querier.future.node_name(node, ssh_options)
          }
        end.collect! do |node|
          node[:node_name] = node[:node_name].value
          node
        end

        partial_nodes = node_list.select do |node|
          known_nodes.value.include?(node[:node_name])
        end

        full_nodes = (node_list - partial_nodes)

        [ full_nodes, partial_nodes ]
      end

      protected

        def full_bootstrap(l_nodes, options)
          chef_conn.node.bootstrap(l_nodes, options)
        end

        def partial_bootstrap(l_nodes, options)
          l_nodes.collect do |node|
            Celluloid::Future.new {
              MB.log.info "Node (#{node[:node_name]}):(#{node[:hostname]}) is already registered with Chef: performing a partial bootstrap"
              updated_node = chef_conn.node.merge_data(node[:node_name], options)
              updated_node.put_secret(ssh_options)
              updated_node.chef_client(ssh_options)
            }
          end.map(&:value)
        end

      private

        def ssh_options
          {
            user: options[:ssh_user],
            password: options[:ssh_password],
            keys: options[:ssh_keys],
            sudo: options[:sudo]
          }
        end
    end
  end
end
