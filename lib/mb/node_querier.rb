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

    # Return the Chef node_name of the target host
    #
    # @param [String] host
    #   hostname of the target node
    # @param [Hash] options
    #   a hash of options to pass to {#ssh_command}
    #
    # @return [String]
    def node_name(host, options = {})
      ruby_script('node_name', host, options)
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
      worker = Ridley::SSH::Worker.new_link(options)
      response = worker.run(host, command)
      worker.terminate

      response
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
    def ruby_script(name, host, options = {})
      name    = name.split('.rb')[0]
      script  = File.read(MB.scripts.join("#{name}.rb"))
      command = "#{EMBEDDED_RUBY_PATH} -e '#{script}'"
      status, response = ssh_command(host, command, options)

      response.stdout.chomp
    end
  end
end
