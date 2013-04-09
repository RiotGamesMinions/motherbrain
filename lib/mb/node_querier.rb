require 'net/sftp'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class NodeQuerier
    class << self
      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(NodeQuerier)]
      def instance
        MB::Application[:node_querier] or raise Celluloid::DeadActorError, "node querier not running"
      end
    end

    extend Forwardable
    include Celluloid
    include MB::Logging
    include MB::Mixin::Services

    finalizer do
      log.info { "Node Querier stopping..." }
    end

    def initialize
      log.info { "Node Querier starting..." }
    end

    # List all of the nodes on the target Chef Server
    #
    # @return [Array<Hash>]
    def list
      chef_connection.node.all
    end

    # Run a Ruby script on the target host and return the result of STDOUT. Only scripts
    # that are located in the Mother Brain scripts directory can be used and they should
    # be identified just by their filename minus the extension
    #
    # @example
    #   node_querier.ruby_script('node_name', '33.33.33.10') => 'vagrant.localhost'
    #
    # @param [String] name
    #   name of the script to run on the target node
    # @param [String] host
    #   hostname of the target node
    #   the MotherBrain scripts directory
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo
    #
    # @raise [RemoteScriptError] if there was an error in execution
    #
    # @note
    #   Use {#_ruby_script_} if the caller of this function is same actor as the receiver. You will
    #   not be able to rescue from the RemoteScriptError thrown by {#ruby_script} but you will
    #   be able to rescue from {#_ruby_script_}.
    #
    # @return [String]
    def ruby_script(name, host, options = {})
      name    = name.split('.rb')[0]
      lines   = File.readlines(MB.scripts.join("#{name}.rb"))
      command_lines = lines.collect { |line| line.gsub('"', "'").strip.chomp }

      status, response = Ridley::HostConnector.best_connector_for(host, options) do |host_connector|
        host_connector.ruby_script(command_lines)
      end

      case status
      when :ok
        response.stdout.chomp
      when :error
        raise MB::RemoteScriptError.new(response.stderr.chomp)
      else
        raise ArgumentError, "unknown status returned from #ruby_script: #{status}"
      end
    end

    # Return the Chef node_name of the target host. A nil value is returned if a
    # node_name cannot be determined
    #
    # @param [String] host
    #   hostname of the target node
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo
    #
    # @return [String, nil]
    def node_name(host, options = {})
      ruby_script('node_name', host, options)
    rescue MB::RemoteScriptError
      nil
    end

    # Run Chef-Client on the target host
    #
    # @param [String] host
    #
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo
    #   bootstrap with sudo
    #
    # @raise [RemoteCommandError] if an execution error occurs in the remote command
    # @raise [RemoteCommandError] if given a blank or nil hostname
    #
    # @return [Ridley::HostConnector::Response]
    def chef_run(host, options = {})
      options = options.dup

      unless host.present?
        abort RemoteCommandError.new("cannot execute a chef-run without a hostname or ipaddress")
      end

      log.info { "Running Chef client on: #{host}" }

      status, response = Ridley::HostConnector.best_connector_for(host, options) do |host_connector|
        host_connector.chef_client
      end

      case status
      when :ok
        log.info { "Completed Chef client run on: #{host}" }
        response
      when :error
        log.info { "Failed Chef client run on: #{host}" }
        abort RemoteCommandError.new(response.stderr.chomp)
      end
    end

    # Place an encrypted data bag secret on the target host
    #
    # @param [String] host
    #
    # @option options [String] :secret
    #   the encrypted data bag secret of the node querier's chef conn will be used
    #   as the default key
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo
    #   bootstrap with sudo
    #
    # @raise [RemoteFileCopyError]
    #
    # @return [Ridley::HostConnector::Response]
    def put_secret(host, options = {})
      options = options.reverse_merge(
        secret: Application.config.chef.encrypted_data_bag_secret_path
      )

      if options[:secret].nil? || !File.exists?(options[:secret])
        return nil
      end

      status, response = Ridley::HostConnector.best_connector_for(host, options) do |host_connector|
        host_connector.put_secret(options[:secret])
      end

      case status
      when :ok
        log.info { "Successfully put secret file on: #{host}" }
        response
      when :error
        log.info { "Failed to put secret file on: #{host}" }
        nil
      end
    end

    # Check if the target host is registered with the Chef server. If the node does not have Chef and
    # ruby installed by omnibus it will be considered unregistered.
    #
    # @example showing a node who is registered to Chef
    #   node_querier.registered?("192.168.1.101") #=> true
    # @example showing a node who does not have ruby or is not registered to Chef
    #   node_querier.registered?("192.168.1.102") #=> false
    #
    # @param [String] host
    #   public hostname of the target node
    #
    # @return [Boolean]
    def registered?(host)
      !registered_as(host).nil?
    end

    # Returns the client name the target node is registered to Chef with.
    # 
    # If the node does not have a client registered with the Chef server or if Chef and ruby were not installed
    # by omnibus this function will return nil.
    #
    # @example showing a node who is registered to Chef
    #   node_querier.registered_as("192.168.1.101") #=> "reset.riotgames.com"
    # @example showing a node who does not have ruby or is not registered to Chef
    #   node_querier.registered_as("192.168.1.102") #=> nil
    #
    # @param [String] host
    #   public hostname of the target node
    #
    # @return [String, nil]
    def registered_as(host)
      if (client_id = node_name(host)).nil?
        return nil
      end

      chef_connection.client.find(client_id).try(:name)
    end
  end
end
