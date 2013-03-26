require 'net/scp'

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

    EMBEDDED_RUBY_PATH = "/opt/chef/embedded/bin/ruby".freeze

    finalizer do
      log.info { "Node Querier stopping..." }
    end

    def initialize
      log.info { "Node Querier starting..." }
    end

    # Run an arbitrary SSH command on the target host
    #
    # @param [String] host
    #   hostname of the target node
    # @param [String] command
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
    # @return [Array]
    def ssh_command(host, command, options = {})
      options            = options.reverse_merge(Application.config[:ssh].to_hash)
      options[:paranoid] = false

      if options[:sudo]
        command = "sudo -i #{command}"
      end

      worker   = Ridley::SSH::Worker.new(options)
      response = worker.run(host, command)
      worker.terminate

      response
    end

    # Copy a file from the local filesystem to the filepath on the target host
    #
    # @param [String] local_file
    # @param [String] remote_file
    # @param [String] host
    # @option options [Hash] :ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [10.0] timeout value for SSH bootstrap
    #   * :sudo (Boolean) [True] bootstrap with sudo
    def copy_file(local_file, remote_file, host, options = {})
      options                  = options.reverse_merge(Application.config.slice(:ssh))
      options[:ssh][:paranoid] = false

      scp_options = options.dup
      scp_options[:ssh] = scp_options[:ssh].slice(*Net::SSH::VALID_OPTIONS)

      MB.log.debug "Copying file '#{local_file}' to '#{host}:#{remote_file}'"

      if options[:ssh][:sudo]
        tmp_location = "/home/#{options[:ssh][:user]}/#{File.basename(remote_file)}"
        Net::SCP.upload!(host, nil, local_file, tmp_location, scp_options)
        ssh_command(host, "mv #{tmp_location} #{remote_file}", options)
      else
        Net::SCP.upload!(host, nil, local_file, remote_file, scp_options)
      end
    end

    # Write the given data to the filepath on the target host
    #
    # @param [#to_s] data
    # @param [String] remote_file
    # @param [String] host
    # @option options [Hash] :ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [10.0] timeout value for SSH bootstrap
    #   * :sudo (Boolean) [True] bootstrap with sudo
    def write_file(data, remote_file, host, options = {})
      file = FileSystem::Tempfile.new
      file.write(data.to_s)
      file.close

      copy_file(file.path, remote_file, host, options)
    ensure
      file.unlink
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
      _ruby_script_(name, host, options = {})
    rescue MB::RemoteScriptError => ex
      abort(ex)
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
      _ruby_script_('node_name', host, options)
    rescue MB::RemoteScriptError
      nil
    end

    # Run Chef-Client on the target host
    #
    # @param [String] host
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
    # @return [Ridley::SSH::Response]
    def chef_run(host, options = {})
      options = options.dup

      unless host.present?
        abort RemoteCommandError.new("cannot execute a chef-run without a hostname or ipaddress")
      end

      log.info { "Running Chef client on: #{host}" }
      status, response = ssh_command(host, "chef-client", options)

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
    # @option options [String] :secret
    #   the encrypted data bag secret of the node querier's chef conn will be used
    #   as the default key
    # @option options [Hash] :ssh
    #   * :user (String) a shell user that will login to each node and perform the bootstrap command on (required)
    #   * :password (String) the password for the shell user that will perform the bootstrap
    #   * :keys (Array, String) an array of keys (or a single key) to authenticate the ssh user with instead of a password
    #   * :timeout (Float) [5.0] timeout value for SSH bootstrap
    #   * :sudo (Boolean) [True] bootstrap with sudo
    #
    # @return [Ridley::SSH::Response]
    def put_secret(host, options = {})
      options = options.reverse_merge(
        secret: Application.config.chef.encrypted_data_bag_secret_path
      )

      if options[:secret].nil? || !File.exists?(options[:secret])
        return nil
      end

      copy_file(options[:secret], '/etc/chef/encrypted_data_bag_secret', host, options)
    end

    private

      # An internal lifting function for {#ruby_script}. Any instance functions delegating to {#ruby_script}
      # should instead delegate to this internal function.
      def _ruby_script_(name, host, options = {})
        name    = name.split('.rb')[0]
        script  = File.read(MB.scripts.join("#{name}.rb"))
        command = "#{EMBEDDED_RUBY_PATH} -e '#{script}'"
        status, response = ssh_command(host, command, options)

        case status
        when :ok
          response.stdout.chomp
        when :error
          raise MB::RemoteScriptError.new(response.stderr.chomp)
        else
          raise ArgumentError, "unknown status returned from #ssh_command: #{status}"
        end
      end
  end
end
