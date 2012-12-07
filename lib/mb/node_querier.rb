require 'net/scp'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class NodeQuerier
    include Celluloid

    EMBEDDED_RUBY_PATH = "/opt/chef/embedded/bin/ruby".freeze

    # @return [Ridley::Connection]
    attr_reader :chef_conn

    # @param [Ridley::Connection] chef_conn
    def initialize(chef_conn)
      @chef_conn = chef_conn
    end

    # Run an arbitrary SSH command on the target host
    #
    # @param [String] host
    #   hostname of the target node
    # @param [String] command
    # @param [Hash] options
    #   a hash of options to pass to Ridley::SSH::Worker
    #
    # @return [Array]
    def ssh_command(host, command, options = {})
      if options[:sudo]
        command = "sudo #{command}"
      end

      worker   = Ridley::SSH::Worker.new(options)
      response = worker.run(host, command)
      worker.terminate

      response
    end

    # @param [String] local_file
    # @param [String] remote_file
    # @param [String] host
    # @param [Hash] options
    #   a hash of options to pass to Net::SCP.upload!
    def copy_file(local_file, remote_file, host, options = {})
      options                  = options.dup
      options[:ssh]            = options[:ssh].slice(*Net::SSH::VALID_OPTIONS)
      options[:ssh][:paranoid] = false

      MB.log.debug "Copying file '#{local_file}' to '#{host}:#{remote_file}'"
      Net::SCP.upload!(host, nil, local_file, remote_file, options)
    end

    # @param [#to_s] data
    # @param [String] remote_file
    # @param [String] host
    # @param [Hash] options
    #   a hash of options to pass to #copy_file
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
    # @param [Hash] options
    #   a hash of options to pass to Ridley::SSH::Worker
    #
    # @raise [RemoteScriptError] if there was an error in execution
    #
    # @return [String]
    def ruby_script(name, host, options = {})
      name    = name.split('.rb')[0]
      script  = File.read(MB.scripts.join("#{name}.rb"))
      command = "#{EMBEDDED_RUBY_PATH} -e '#{script}'"
      status, response = ssh_command(host, command, options)

      case status
      when :ok
        response.stdout.chomp
      when :error
        raise RemoteScriptError, response.stderr.chomp
      end
    end

    # Return the Chef node_name of the target host. A nil value is returned if a
    # node_name cannot be determined
    #
    # @param [String] host
    #   hostname of the target node
    # @param [Hash] options
    #   a hash of options to pass to {#ssh_command}
    #
    # @return [String, nil]
    def node_name(host, options = {})
      ruby_script('node_name', host, options)
    rescue RemoteScriptError
      nil
    end

    # Run Chef-Client on the target host
    #
    # @param [String] host
    # @option options [Hash] :ssh
    #
    # @raise [RemoteCommandError] if an execution error occurs in the remote command
    #
    # @return [Ridley::SSH::Response]
    def run_chef(host, options = {})
      options = options.dup
      options[:ssh] ||= {
        sudo: true
      }
      
      status, response = ssh_command(host, "chef-client", options[:ssh])
      case status
      when :ok
        response
      when :error
        raise RemoteCommandError, response.stderr.chomp
      end
    end

    # Place an encrypted data bag secret on the target host
    #
    # @param [String] host
    # @option options [Hash] :ssh
    # @option options [String] :secret
    #   the encrypted data bag secret of the node querier's chef conn will be used
    #   as the default key
    #
    # @return [Ridley::SSH::Response]
    def put_secret(host, options = {})
      options = options.dup
      options[:secret] ||= chef_conn.encrypted_data_bag_secret_path

      if options[:secret].nil? || !File.exists?(options[:secret])
        return nil
      end

      copy_file(options[:secret], '/etc/chef/encrypted_data_bag_secret', host, options)
    end
  end
end
