require 'ef/rest'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    class EnvironmentFactory
      include Provisioner

      register_provisioner :environment_factory,
        default: true

      # How often to check with Environment Factory to see if the environment has been
      # created and is ready
      #
      # @return [Float]
      attr_accessor :interval

      # @return [EF::REST::Connection]
      attr_accessor :connection

      # @option options [#to_f] :interval
      # @option options [#to_s] :api_url
      # @option options [#to_s] :api_key
      # @option options [Hash] :ssl
      def initialize(options = {})
        @interval   = (options.delete(:interval) || 5.0).to_f
        @connection = EF::REST.connection(options)
      end

      # @param [String] env_name
      # @param [Hash] manifest
      # @return [Hash]
      def run(env_name, manifest)
        connection.environment.create(env_name, manifest)

        until connection.environment.created?(env_name)
          sleep self.interval
        end

        connection.environment.find(env_name)
      end
    end
  end
end
