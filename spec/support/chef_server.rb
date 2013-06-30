require 'chef_zero/server'
require_relative 'spec_helpers'

module MotherBrain::RSpec
  module ChefServer
    class << self
      def clear_data
        server.clear_data
      end

      def clear_request_log
        @request_log = Array.new
      end

      def port
        if ENV['CHEF_API_URL']
          ENV['CHEF_API_URL'].split(?:).last.to_i
        else
          28890
        end
      end

      def request_log
        @request_log ||= Array.new
      end

      def server
        @server ||= ChefZero::Server.new(port: port, generate_real_keys: false)
      end

      def server_url
        (@server && @server.url) || "http://localhost:#{port}"
      end

      def start
        return if running?

        server.start_background
        server.on_response do |request, response|
          request_log << [ request, response ]
        end
        clear_request_log

        @running = true

        server
      end

      def stop
        @server.stop if @server
      end

      def running?
        @running
      end
    end

    include MotherBrain::SpecHelpers
    include MotherBrain::RSpec::Berkshelf

    def chef_client(name, hash = Hash.new)
      load_data(:clients, name, hash)
    end

    def chef_cookbook(name, version, options = {})
      options           = options.reverse_merge(with_plugin: true)
      options[:version] = version
      options[:path]    = tmp_path.join("cookbook-#{name}-#{version}")

      ridley_zero do |r|
        r.cookbook.upload(generate_cookbook(name, options))
      end
    end

    def chef_data_bag(name, hash = Hash.new)
      ChefServer.server.load_data({ 'data' => { name => hash }})
    end

    def chef_environment(name, hash = Hash.new)
      load_data(:environments, name, hash)
    end

    def chef_node(name, hash = Hash.new)
      load_data(:nodes, name, hash)
    end

    def chef_role(name, hash = Hash.new)
      load_data(:roles, name, hash)
    end

    def ridley_zero(&block)
      Ridley::Client.open(server_url: ChefServer.server_url, client_name: "reset",
        client_key: fixtures_path.join('fake_key.pem').to_s, &block)
    end

    private

      def load_data(key, name, hash)
        ChefServer.server.load_data(key.to_s => { name => JSON.fast_generate(hash) })
      end
  end
end
