module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <reset@riotgames.com>
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

        full_nodes, partial_nodes = nodes.partition { |node| node[:node_name].nil? }

        [].tap do |futures|
          if full_nodes.any?
            hostnames = full_nodes.collect { |node| node[:hostname] }
            futures << future(:full_bootstrap, hostnames, options)
          end

          if partial_nodes.any?
            futures << future(:partial_bootstrap, partial_nodes, options.slice(:attributes, :run_list))
          end
        end.map(&:value).flatten
      end

      # Query the given hostnames and return an expanded view containing an array of Hashes
      # each representing a hostname. Each hash contains a hostname and node_name key. The
      # hostname is the address to communicate to the node with and the node_name is the
      # name the node is identified in Chef as.
      #
      # If the node has not registered with the Chef server then the node_name value will
      # be nil.
      #
      # @example showing one node who has been registered with Chef and one which has not
      #   worker = Worker.new(..)
      #   worker.nodes #=> [
      #     {
      #       hostname: "riot_one.riotgames.com",
      #       node_name: "riot_one"
      #     },
      #     {
      #       hostname: "riot_two.riotgames.com",
      #       node_name: nil
      #     }
      #   ]
      #
      # @option options [Boolean] :force (false)
      #   reload the cached value of nodes if it has been cached
      #
      # @return [Array<Hash>]
      def nodes(options = {})
        options = options.reverse_merge(force: false)

        if options[:force]
          @nodes = nil
        end

        @nodes ||= hosts.collect do |host|
          [ host, node_querier.registered_as(host) ]
        end.collect do |host, client_name|
          {
            hostname: host,
            node_name: client_name.value
          }
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
      # @param [Array<Hash>] hostnames
      #   an array of hashes containing node data
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
            rescue Ridley::Errors::HTTPNotFound, RemoteCommandError, RemoteFileCopyError => ex
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
