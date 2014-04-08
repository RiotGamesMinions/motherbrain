module MotherBrain
  module Bootstrap
    # @api private
    class Worker
      # Used internally within the {Bootstrap::Worker} to identify hosts which should be
      # partially or fully bootstrapped.
      #
      # @api private
      class Host
        # The fully qualified hostname of the machine
        #
        # @example
        #   "reset.riotgames.com"
        #
        # @return [String]
        attr_reader :hostname

        # @param [String] hostname
        #   A fully qualified hostname for a machine
        def initialize(hostname)
          @hostname = hostname
        end

        # @return [Boolean]
        def full_bootstrap?
          node_name.nil?
        end

        # The name of the machine as seen in Chef
        #
        # @example
        #   "reset"
        #
        # @return [String]
        def node_name
          @node_name ||= NodeQuerier.instance.registered_as(hostname)
        end

        # @return [Boolean]
        def partial_bootstrap?
          node_name.present?
        end

        def to_s
          "#{node_name}(#{hostname})"
        end
      end

      include Celluloid
      include MB::Logging
      include MB::Mixin::Services

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
      #   worker = Worker.new
      #   worker.run("cloud-1.riotgames.com") #=> {
      #     node: "cloud-1.riotgames.com",
      #     status: :ok,
      #     message: "",
      #     bootstrap_type: :full
      #   }
      #
      # @param [String] address
      #   a hostname or ipaddress to bootstrap
      #
      # @option options [String] :environment
      #   environment to join the node to (default: '_default')
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
      # @return [Hash]
      def run(address, options = {})
        host = Host.new(address)
        chef_connection.node.bootstrap(host.hostname, options)
      end

      # Perform a bootstrap on a group of nodes which have not yet been registered with the Chef server
      # and may not have Ruby, Chef, or other requirements installed.
      #
      # @example
      #   host = Host.new("cloud-1.riotgames.com")
      #
      #   worker.full_bootstrap(host) #=> {
      #     node_name: "cloud-1",
      #     hostname: "cloud-1.riotgames.com",
      #     status: :ok
      #     message: "",
      #     bootstrap_type: :full
      #   }
      #
      # @param [Worker::Host] host
      #   a host to bootstrap
      #
      # @option options [String] :environment
      #   environment to join the node to (default: '_default')
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
      # @return [Hash]
      def full_bootstrap(host, options = {})
        options = options.reverse_merge(
          run_list: Array.new,
          attributes: Hash.new,
          hints: Hash.new,
          sudo: true
        )

        begin
          options[:template] = MB::Bootstrap::Template.find(options[:template])
        rescue MB::BootstrapTemplateNotFound => e
          abort e
        end
        options.delete(:template) if options[:template].nil?

        ssh_response = chef_connection.node.bootstrap(host.hostname, options)

        {}.tap do |response|
          response[:node_name]      = nil
          response[:hostname]       = ssh_response.host
          response[:bootstrap_type] = :full
          response[:message]        = ""
          response[:status]         = :ok

          if ssh_response.error?
            response[:status]  = :error
            response[:message] = ssh_response.stderr.chomp
          end
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
      #   host = Host.new("cloud-1.riotgames.com")
      #   worker.partial_bootstrap(host) #=> {
      #     node_name: "cloud-1",
      #     hostname: "cloud-1.riotgames.com",
      #     status: :ok
      #     message: "",
      #     bootstrap_type: :partial
      #   }
      #
      # @param [Worker::Host] host
      #   a host to bootstrap
      #
      # @option options [Array] :run_list
      #   a chef run list
      # @option options [Hash] :attributes
      #   attributes to set on the node at normal precedence
      #
      # @return [Hash]
      def partial_bootstrap(host, options = {})
        log.info "#{host} is already registered with Chef. Performing a partial bootstrap."

        {}.tap do |response|
          response[:node_name]      = host.node_name
          response[:hostname]       = host.hostname
          response[:bootstrap_type] = :partial
          response[:message]        = ""
          response[:status]         = :ok

          begin
            chef_connection.node.merge_data(host.node_name, options.slice(:run_list, :attributes))
            node_querier.put_secret(host.hostname)
            node_querier.chef_run(host.hostname)
          rescue Ridley::Errors::ResourceNotFound => ex
            response[:status]  = :error
            response[:message] = "Host #{host} has a client on the node and a matching client on the Chef server, " +
              "but there is no matching node object on the Chef server for the client. This should not happen. " +
              "Run `mb purge #{host}` or manually destroy the client on the node itself and the node object on " +
              "the Chef server and re-run your bootstrap."
            # JW TODO: We can recover here by creating the node object. However, we can't do this right
            # now because OHC/OPC have ACLs associated with the node object. When we create the object the
            # API user that we are acting as will be the only user with full permissions to the node
            # object resulting in a 403 error when the node attempts to save itself back to the Chef server.
            #
            # TLDR; The undocumented ACL endpoints need to be implemented in Ridley to support graceful
            # recovery. https://github.com/RiotGames/ridley/issues/147
          rescue Exception => ex
            response[:status]  = :error
            response[:message] = ex.to_s
          end
        end
      end
    end
  end
end
