require 'ef/rest'

module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    class EnvironmentFactory
      class << self
        # Convert the given provisioner manifest to a hash usable by Environment Factory
        #
        # @param [Provisioner::Manifest] manifest
        #
        # @return [Hash]
        def convert_manifest(manifest)
          [].tap do |ef_manifest|
            manifest.each_pair do |instance_size, groups|
              groups.each do |name, amount|
                amount.times do
                  ef_manifest << { instance_size: instance_size }
                end
              end
            end
          end
        end
      end

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

      # Create an environment of the given name and provision nodes in based on the contents
      # of the given manifest
      #
      # @param [String] env_name
      # @param [Provisioner::Manifest] manifest
      #
      # @return [Hash]
      def up(env_name, manifest)
        connection.environment.create(env_name, self.class.convert_manifest(manifest))

        until connection.environment.created?(env_name)
          sleep self.interval
        end

        connection.environment.find(env_name)
      end

      # Tear down the given environment and the nodes in it
      #
      # @param [String] env_name
      #
      # @return [Hash, nil]
      def down(env_name)
        connection.environment.destroy(env_name)
      end
    end
  end
end
