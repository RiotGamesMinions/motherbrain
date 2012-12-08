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

      # @return [Hash]
      attr_reader :options

      # @param [String] group_id
      #   a string containing a group_id for the nodes being bootstrapped
      #     'activemq::master'
      #     'mysql::slave'
      # @param [Array<String>] hosts
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
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      def initialize(group_id, hosts, chef_conn, options = {})
        @group_id     = group_id
        @hosts        = Array(hosts)
        @chef_conn    = chef_conn
        @options      = options
      end

      # @example
      #   worker.run => [
      #     #<Ridley::SSH::ResponseSet @failures=[], @successes=[]>,
      #     #<Ridley::SSH::ResponseSet @failures=[], @successes=[]>
      #   ]
      #
      # @return [Array<Ridley::SSH::ResponseSet]
      def run
        MB.log.info "Bootstrapping group: '#{group_id}' [ #{hosts.join(', ')} ] with options: '#{options}'"
        unless hosts && hosts.any?
          MB.log.info "No hosts in group: '#{group_id}'. Skipping..."
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
              partial_bootstrap(partial_nodes, options.slice(:ssh, :attributes, :run_list))
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
      # @example splitting hosts into two groups based on chef client presence
      #   @hosts => [
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

        partial_nodes = self.nodes.select do |node|
          known_nodes.value.include?(node[:node_name])
        end

        full_nodes = (self.nodes - partial_nodes)
        full_nodes.collect! { |node| node[:hostname] }

        [ full_nodes, partial_nodes ]
      end

      # Query the given hostnames and return an expanded view containing an array of Hashes
      # each representing a hostname. Each hash contains a hostname and node_name key. The
      # hostname is the address to communicate to the node with and the node_name is the
      # name the node is identified in Chef as.
      #
      # @option options [Boolean] :force
      #
      # @example
      #   worker.nodes => [
      #     {
      #       hostname: "riot_one.riotgames.com",
      #       node_name: "riot_one"
      #     },
      #     {
      #       hostname: "riot_two.riotgames.com",
      #       node_name: "riot_two"
      #     }
      #   ]
      #
      # @return [Hash]
      def nodes
        if options[:force]
          @nodes = nil
        end

        @nodes ||= hosts.collect do |host|
          {
            hostname: host,
            node_name: Application.node_querier.future.node_name(host, options[:ssh])
          }
        end.collect! do |node|
          node[:node_name] = node[:node_name].value
          node
        end
      end

      protected

        # @param [Array<String>] target_nodes
        # @param [Hash] options
        #
        # @return [Ridley::SSH::ResponseSet]
        def full_bootstrap(target_nodes, options)
          chef_conn.node.bootstrap(target_nodes, options)
        end

        # @param [Array<Hash>] target_nodes
        # @param [Hash] options
        #
        # @return [Ridley::SSH::ResponseSet]
        def partial_bootstrap(target_nodes, options)
          Ridley::SSH::ResponseSet.new.tap do |response_set|
            target_nodes.collect do |node|
              Celluloid::Future.new {
                MB.log.info "Node (#{node[:node_name]}):(#{node[:hostname]}) is already registered with Chef: performing a partial bootstrap"
                
                chef_conn.node.merge_data(node[:node_name], options)
                Application.node_querier.put_secret(node[:hostname], options.slice(:ssh))
                Application.node_querier.chef_run(node[:hostname], options[:ssh])
              }
            end.map do |future|
              response_set.add_response(future.value)
            end
          end
        end

      private

        attr_reader :hosts
    end
  end
end
