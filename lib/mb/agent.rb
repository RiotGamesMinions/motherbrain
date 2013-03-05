require 'dcell'
require 'chef'
require 'ohai'

module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module Agent
    autoload :ChefClient, 'mb/agent/chef_client'
    autoload :JobNotifier, 'mb/agent/job_notifier'
    autoload :Ohai, 'mb/agent/ohai'

    class SupervisionGroup < Celluloid::SupervisionGroup
      cattr_accessor :chef_options
      cattr_accessor :ohai_options

      supervise Agent::ChefClient, as: :chef_client, args: chef_options
      supervise Agent::Ohai, as: :ohai, args: ohai_options
    end

    class << self
      # @return [String]
      attr_reader :node_id
      # @return [String]
      attr_reader :host
      # @return [Integer]
      attr_reader :port

      # @return [Hash]
      def default_options
        {
          node_id: nil,
          host: "127.0.0.1",
          port: 27400,
          chef_options: Hash.new,
          ohai_options: Hash.new
        }
      end

      # Node ID to register this agent as
      #
      # @return [String, nil]
      def node_id
        @node_id ||= begin
          ohai = ::Ohai::System.new
          ohai.require_plugin("#{Agent::Ohai.os}/hostname")
          ohai[:fqdn] || ohai[:hostname]
        end
      end

      # Run the agent in the foreground
      def run
        DCell.start id: node_id, addr: "tcp://#{host}:#{port}"
        Agent::SupervisionGroup.run
      end

      # Run the agent in the background
      def run!
        DCell.start id: node_id, addr: "tcp://#{host}:#{port}"
        Agent::SupervisionGroup.run!
      end

      # Setup the agent
      #
      # @param [Hash] options
      #
      # @see {#start} for options
      def setup(options = {})
        options = options.reverse_merge(default_options)

        @node_id = options[:node_id]
        @host    = options[:host]
        @port    = options[:port]
        Agent::SupervisionGroup.chef_options = options[:chef_options]
        Agent::SupervisionGroup.ohai_options = options[:ohai_options]
      end

      # Setup and run the agent in the foreground
      #
      # @option options [String] :node_id
      # @option options [String] :host
      # @option options [Integer] :port
      # @option options [Hash] :chef_options
      # @option options [Hash] :ohai_options
      def start(options = {})
        setup(options)
        run
      end
    end
  end
end
