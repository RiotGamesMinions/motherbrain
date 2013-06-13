require 'ef/rest'
EF::REST.set_logger(MB.logger)

module MotherBrain
  module Provisioner
    # Provisioner adapter for Environment Factory. Node/Environment creation will be
    # delegated to an Environment Factory server.
    class EnvironmentFactory < Provisioner::Base
      class << self
        # Convert the given provisioner manifest to a hash usable by Environment Factory
        #
        # @param [Provisioner::Manifest] manifest
        #
        # @return [Hash]
        def convert_manifest(manifest)
          ef_manifest = Array.new

          manifest.node_groups.each do |node_group|
            count = node_group[:count] || 1
            type = node_group[:type]

            count.times do
              ef_manifest << { instance_size: type }
            end
          end

          ef_manifest
        end

        # Convert the created environment response from environment factory into a usable format
        # for motherbrain internals
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

      register_provisioner :environment_factory

      # Create an environment of the given name and provision nodes in based on the contents
      # of the given manifest
      #
      # @param [Job] job
      #   a job to track the progress of this action
      # @param [String] env_name
      #   the name of the environment to create
      # @param [Provisioner::Manifest] manifest
      #   a manifest describing the way the environment should look
      #
      # @option options [Boolean] :skip_bootstrap (false)
      #
      # @raise [MB::ProvisionError]
      #   if a caught error occurs during provisioning
      #
      # @return [Array<Hash>]
      def up(job, env_name, manifest, plugin, options = {})
        options    = options.reverse_merge(skip_bootstrap: false, interval: 30.0)
        connection = new_connection(options)

        begin
          job.set_status("Creating new environment")
          connection.environment.create(env_name, self.class.convert_manifest(manifest))
        rescue EF::REST::HTTPUnprocessableEntity; end

        until connection.environment.created?(env_name)
          job.set_status("Waiting for environment to be created")
          sleep options[:interval].to_f
        end

        job.set_status("Environment created")

        response = self.class.handle_created(connection.environment.find(env_name, force: true))
        self.class.validate_create(response, manifest)
        response
      rescue UnexpectedProvisionCount, EF::REST::Error => ex
        abort ProvisionError.new(ex)
      end

      # Tear down the given environment and the nodes in it
      #
      # @param [Job] job
      #   a job to track the progress of this action
      # @param [String] env_name
      #   the name of the environment to destroy
      #
      # @raise [MB::ProvisionError]
      #   if a caught error occurs during provisioning
      #
      # @return [Boolean]
      def down(job, env_name, options = {})
        job.set_status("Sending request to environment factory to destroy environment")
        connection = new_connection(options)
        connection.environment.destroy(env_name)

        until destroyed?(connection, env_name)
          job.set_status("Waiting for environment to be destroyed")
          sleep 2
        end

        destroy_environment job, env_name

        true
      rescue EF::REST::Error => ex
        abort ProvisionError.new(ex)
      end

      private

        # @option options [#to_s] :api_url
        # @option options [#to_s] :api_key
        # @option options [Hash] :ssl
        def new_connection(options = {})
          options = options.reverse_merge(
            api_url: config_manager.config[:ef][:api_url],
            api_key: config_manager.config[:ef][:api_key],
            ssl: config_manager.config[:ssl].to_hash
          )

          EF::REST.connection(options)
        end

        # Has the given environment been destroyed?
        #
        # @param [String] environment
        #
        # @return [Boolean]
        def destroyed?(connection, environment)
          response = connection.environment.find(environment, force: true)
          response[:status] == "pending"
        end
    end
  end
end
