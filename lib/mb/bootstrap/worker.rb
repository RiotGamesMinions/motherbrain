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

      # @param [Array<String>] hosts
      #   an array of hostnames or ipaddresses to bootstrap
      #
      #   @example
      #     [ '33.33.33.10', 'reset.riotgames.com' ]
      def initialize(hosts)
        @hosts = Array(hosts)
      end

      # Run a bootstrap on each of the hosts given to this instance of {Worker}. There are two different kinds of
      # bootstrap processes which may be run on a node; a partial bootstrap and a full bootstrap.
      #
      # Partial Bootstrap: a node will be partially bootstrapped if it has
      #   1. Chef installed by omnibus
      #   2. Ruby installed by omnibus
      #   3. A Chef client registered with the Chef server.
      #      note: the name of the client is the "node_name" of the node. This obtained by running the
      #            ruby node name script "script/node_name.rb" on the node.
      #
      # Full Bootstrap: a node will be fully bootstrapped if it does not satisfy all of the criteria for a
      #   partial bootstrap.
      #
      # @example
      #   hosts = [
      #     "cloud-1.riotgames.com",
      #     "cloud-2.riotgames.com"
      #   ]
      #   worker = Worker.new(hosts)
      #
      #   worker.run #=> [
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
      #
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to use in the first Chef run
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
      # @option options [String] :chef_version
      #   version of Chef to install on the node
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
      # @option options [String] :bootstrap_proxy (nil)
      #   URL to a proxy server to bootstrap through
      #
      # @return [Array<Hash>]
      def run(options = {})
        if hosts.empty?
          return Array.new
        end

        full_nodes    = Array.new
        partial_nodes = Array.new
        full_nodes, partial_nodes = bootstrap_type_filter

        [].tap do |futures|
          if full_nodes.any?
            futures << future(:full_bootstrap, full_nodes, options)
          end

          if partial_nodes.any?
            futures << future(:partial_bootstrap, partial_nodes, options.slice(:attributes, :run_list))
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
      #   hosts = [
      #     "no-client1.riotgames.com",
      #     "no-client2.riotgames.com",
      #     'has-client.riotgames.com"'
      #   ]
      #   worker = Worker.new(hosts)
      #
      #   worker.bootstrap_type_filter => [
      #     [ "no-client1.riotgames.com", "no-client2.riotgames.com" ],
      #     [
      #       {
      #         hostname: "has-client.riotgames.com",
      #         node_name: "has-client.internal"
      #       }
      #     ]
      #   ]
      #
      # @return [Array<Array>]
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
      # @example
      #   worker = Worker.new(..)
      #   worker.nodes #=> [
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
      # @option options [Boolean] :force (false)
      #
      # @return [Hash]
      def nodes(options = {})
        options = options.reverse_merge(force: false)

        if options[:force]
          @nodes = nil
        end

        @nodes ||= hosts.collect do |host|
          {
            hostname: host,
            node_name: node_querier.future(:node_name, host)
          }
        end.collect do |node|
          node[:node_name] = node[:node_name].value
          node
        end
      end

      # Perform a bootstrap on a group of nodes which have not yet been registered with the Chef server
      # and may not have Ruby, Chef, or other requirements installed.
      #
      # @example
      #   hostnames = [
      #     "cloud-1.riotgames.com",
      #     "cloud-2.riotgames.com"
      #   ]
      #   worker = Worker.new(...)
      #
      #   worker.full_bootstrap(target_nodes) #=> [
      #     {
      #       node_name: "cloud-1",
      #       hostname: "cloud-1.riotgames.com",
      #       status: :ok
      #       message: "",
      #       bootstrap_type: :full
      #     },
      #     {
      #       node_name: "cloud-2",
      #       hostname: "cloud-2.riotgames.com",
      #       status: :error,
      #       message: "client verification error",
      #       bootstrap_type: :full
      #     }
      #   ]
      #
      # @param [Array<String>] hostnames
      #   an array of hostnames to fully bootstrap
      #
      # @option options [String] :chef_version
      #   version of Chef to install on the node
      # @option options [Hash] :attributes (Hash.new)
      #   a hash of attributes to use in the first Chef run
      # @option options [Array] :run_list (Array.new)
      #   an initial run list to bootstrap with
      # @option options [Hash] :hints (Hash.new)
      #   a hash of Ohai hints to place on the bootstrapped node
      # @option options [Boolean] :sudo (true)
      #   bootstrap with sudo
      #
      # @return [Array<Hash>]
      def full_bootstrap(hostnames, options = {})
        options = options.reverse_merge(
          run_list: Array.new,
          attributes: Hash.new,
          hints: Hash.new,
          sudo: true
        )

        chef_connection.node.bootstrap(hostnames, options).collect do |ssh_response|
          response = {
            node_name: nil,
            hostname: ssh_response.host,
            bootstrap_type: :full,
            message: "",
            status: nil
          }

          if ssh_response.error?
            response[:status]  = :error
            response[:message] = ssh_response.stderr.chomp
          else
            response[:status] = :ok
          end

          response
        end
      end

      # Perform a bootstrap on a group of nodes which have already been registered with the Chef server.
      #
      # Partial bootstrap steps:
      #   1. The given values given for the run_list and attributes options will be merged with the existing
      #      node data
      #   2. Your organization's secret key will be placed on the node
      #   3. Perform a chef client run on the target node
      #
      # @example
      #   nodes = [
      #     {
      #       node_name: "reset",
      #       hostname: "reset.riotgames.com"
      #     },
      #     {
      #       node_name: "cloud-1",
      #       hostname: "cloud-1.riotgames.com"
      #     }
      #   ]
      #   worker = Worker.new(...)
      #
      #   worker.partial_bootstrap(nodes) #=> [
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
      #
      # @param [Array<Hash>] nodes
      #   an array of hashes containing node data
      #
      # @option options [Array] :run_list
      #   a chef run list
      # @option options [Hash] :attributes
      #   attributes to set on the node at normal precedence
      #
      # @return [Array<Hash>]
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
              chef_connection.node.merge_data(node_name, options.slice(:run_list, :attributes))
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
