module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include MB::Logging
      include MB::Mixin::Services

      # @return [Array<String>]
      attr_reader :hosts
      # @return [Hash]
      attr_reader :options

      # @param [Array<String>] hosts
      #   an array of hostnames or ipaddresses to bootstrap
      #
      #   @example
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
      def initialize(hosts, options = {})
        @hosts   = Array(hosts)
        @options = options
      end

      # Run a bootstrap on each of the hosts given to this instance of {Worker}
      #
      # @raise [MB::BootstrapError]
      #   if there was an error during the bootstrap process
      #
      # @return [Array<Hash>]
      #   [
      #     {
      #       node: "cloud-1.riotgames.com",
      #       status: :ok
      #       message: ""
      #       bootstrap_type: :full
      #     },
      #     {
      #       node: "cloud-2.riotgames.com",
      #       status: :error,
      #       message: "client verification error"
      #       bootstrap_type: :partial
      #     }
      #   ]
      def run
        unless hosts && hosts.any?
          return [ :ok, [] ]
        end

        full_nodes    = Array.new
        partial_nodes = Array.new
        full_nodes, partial_nodes = bootstrap_type_filter

        [].tap do |futures|
          unless full_nodes.empty?
            future(:_full_bootstrap_, full_nodes, options)
          end

          unless partial_nodes.empty?
            future(:_partial_bootstrap_, partial_nodes, options.slice(:attributes, :run_list))
          end
        end.map(&:value).flatten
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
          chef_connection.node.all.map { |node| node.name.to_s }
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
            node_name: node_querier.future.node_name(host)
          }
        end.collect! do |node|
          node[:node_name] = node[:node_name].value
          node
        end
      end

      # @param [Array<String>] target_nodes
      # @param [Hash] options
      #
      # @return [Array<Hash>]
      #   [
      #     {
      #       node: "cloud-1.riotgames.com",
      #       status: :ok
      #       message: "",
      #       bootstrap_type: :full
      #     },
      #     {
      #       node: "cloud-2.riotgames.com",
      #       status: :error,
      #       message: "client verification error",
      #       bootstrap_type: :full
      #     }
      #   ]
      def full_bootstrap(target_nodes, options)
        chef_connection.node.bootstrap(target_nodes, options)
      rescue Ridley::Errors::RidleyError => ex
        abort BootstrapError.new(ex.to_s)
      end

      # Perform a bootstrap on a group of nodes which have already been registered with the Chef server.
      #
      # Partial bootstrap steps:
      #   1. The given values given for the run_list and attributes options will be merged with the existing
      #      node data
      #   2. Your organization's secret key will be placed on the node
      #   3. Perform a chef client run on the target node
      #
      # @param [Array<Hash>] nodes
      #   an array of hashes containing node data
      #
      #   @example
      #   [
      #     {
      #       node_name: "reset",
      #       hostname: "reset.riotgames.com"
      #     },
      #     {
      #       node_name: "cloud-1",
      #       hostname: "cloud-1.riotgames.com"
      #     }
      #   ]
      #
      # @option options [Array] :run_list
      #   a chef run list
      # @option options [Hash] :attributes
      #   attributes to set on the node at normal precedence
      #
      # @return [Array<Hash>]
      #   [
      #     {
      #       node_name: "cloud-1",
      #       hostname: "cloud-1.riotgames.com",
      #       status: :ok,
      #       message: "",
      #       bootstrap_type: :partial
      #     },
      #     {
      #       node_name: "cloud-2",
      #       hostname: "cloud-2.riotgames.com",
      #       status: :error,
      #       message: "client verification error",
      #       bootstrap_type: :partial
      #     }
      #   ]
      def partial_bootstrap(nodes, options = {})
        nodes.collect do |node|
          Celluloid::Future.new {
            hostname  = node[:hostname]
            node_name = node[:node_name]

            log.info {
              "Node (#{node_name}):(#{hostname}) is already registered with Chef: performing a partial bootstrap"
            }

            response = {
              node_name: node_name,
              hostname: hostname,
              bootstrap_type: :partial,
              message: "",
              status: nil
            }

            begin
              chef_connection.node.merge_data(node_name, options)
              node_querier.put_secret(hostname)
              node_querier.chef_run(hostname)

              response[:status] = :ok
            rescue Ridley::Errors::HTTPNotFound, RemoteCommandError => ex
              response[:status]  = :error
              response[:message] = ex.to_s
            end

            response
          }
        end.map(&:value)
      end
    end
  end
end
