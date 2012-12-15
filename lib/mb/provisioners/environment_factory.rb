require 'ef/rest'
EF::REST.set_logger(MB.logger)

module MotherBrain
  module Provisioners
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Provisioner adapter for Environment Factory. Node/Environment creation will be
    # delegated to an Environment Factory server.
    #
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

        # Convert the created environment response from environment factory into a usable format
        # for MotherBrain internals
        #
        # @example
        #   [
        #     {
        #       instance_type: "m1.large",
        #       public_hostname: "node1.riotgames.com"
        #     },
        #     {
        #       instance_type: "m1.small",
        #       public_hostname: "node2.riotgames.com"
        #     }
        #   ]
        #
        # @param [Hash] ef_response
        #
        # @return [Array<Hash>]
        def handle_created(ef_response)
          ef_response[:nodes].collect do |node|
            {
              instance_type: node[:automatic][:eucalyptus][:instance_type],
              public_hostname: node[:automatic][:eucalyptus][:public_hostname]
            }
          end
        end
      end

      include Provisioner
      include MB::Logging

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
      #   set a polling interval to see if the environment is ready (default: 30.0)
      # @option options [#to_s] :api_url
      # @option options [#to_s] :api_key
      # @option options [Hash] :ssl
      def initialize(options = {})
        @interval   = (options.delete(:interval) || 30.0).to_f
        @connection = EF::REST.connection(options)
      end

      # Create an environment of the given name and provision nodes in based on the contents
      # of the given manifest
      #
      # @param [Job] job
      # @param [String] env_name
      # @param [Provisioner::Manifest] manifest
      #
      # @return [Job]
      def up(job, env_name, manifest)
        job.transition(Job::Status::RUNNING)
        connection.environment.create(env_name, self.class.convert_manifest(manifest))

        until connection.environment.created?(env_name)
          sleep self.interval
        end

        response = self.class.handle_created(connection.environment.find(env_name, force: true))
        self.class.validate_create(response, manifest)
        job.transition(Job::Status::SUCCESS)
      rescue EF::REST::Error => e
        job.transition(Job::Status::FAILURE, e)
      rescue => e
        log.fatal { "An unknown error occured during destroy_provision: #{e}"}
        job.transition(Job::Status::FAILURE, "internal error")
      end

      # Tear down the given environment and the nodes in it
      #
      # @param [Job] job
      # @param [String] env_name
      #
      # @return [Job]
      def down(job, env_name)
        job.transition(Job::Status::RUNNING)
        connection.environment.destroy(env_name)
        job.transition(Job::Status::SUCCESS)
      rescue EF::REST::Error => e
        job.transition(Job::Status::FAILURE, e)
      rescue => e
        log.fatal { "An unknown error occured during destroy_provision: #{e}"}
        job.transition(Job::Status::FAILURE, "internal error")
      end
    end
  end
end
