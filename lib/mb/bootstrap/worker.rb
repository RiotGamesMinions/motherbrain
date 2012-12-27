module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

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
      #
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to use in the first Chef run
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
      # @option options [Boolean] :force
      #   ignore and bypass any existing locks on an environment
      # @option options [Hash] :ssh
      #   * :user (String) a shell user that will login to each node and perform the bootstrap command on
      #   * :password (String) the password for the shell user that will perform the bootstrap
      #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
      #   * :timeout (Float) [10.0] timeout value for SSH bootstrap
      #   * :sudo (Boolean) [True] bootstrap with sudo
      # @option options [String] :server_url
      #   URL to the Chef API to bootstrap the target node(s) to
      # @option options [String] :client_name
      #   name of the client used to authenticate with the Chef API
      # @option options [String] :client_key
      #   filepath to the client's private key used to authenticate with the Chef API
      # @option options [String] :organization
      #   the Organization to connect to. This is only used if you are connecting to
      #   private Chef or hosted Chef
      # @option options [String] :validator_client
      #   the name of the Chef validator client to use in bootstrapping
      # @option options [String] :validator_path
      #   filepath to the validator used to bootstrap the node
      # @option options [String] :encrypted_data_bag_secret_path
      #   filepath on your host machine to your organizations encrypted data bag secret
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [String] :template ("omnibus")
      #   bootstrap template to use
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      def initialize(group_id, hosts, options = {})
        @group_id = group_id
        @hosts    = Array(hosts)
        @options  = options
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
            node_name: Application.node_querier.future.node_name(host)
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
                Application.node_querier.put_secret(node[:hostname])
                Application.node_querier.chef_run(node[:hostname])
              }
            end.map do |future|
              response_set.add_response(future.value)
            end
          end
        end

        def chef_conn
          Application.ridley
        end

      private

        attr_reader :hosts
    end
  end
end
