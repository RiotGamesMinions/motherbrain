module MotherBrain
  module Provisioner
    autoload :Manager, 'mb/provisioner/manager'
    autoload :Manifest, 'mb/provisioner/manifest'

    class << self
      attr_reader :default_id

      # @param [Class] klass
      # @option options [Boolean] :default
      #
      # @raise [ProvisionerRegistrationError] if a provisioner is registered as the default provisioner when
      #   a default provisioner already exists
      #
      # @return [Set]
      def register(klass, options = {})
        validate_provisioner_class(klass)

        unless get(klass.provisioner_id).nil?
          raise ProvisionerRegistrationError,
            "A provisioner with the id '#{klass.provisioner_id}' has already been registered"
        end

        if options[:default]
          unless @default_id.nil?
            raise ProvisionerRegistrationError, "A default provisioner has already been defined (#{default_id})"
          end

          @default_id = klass.provisioner_id
        end

        all.add(klass)
      end

      # List of all the registered provisioners
      #
      # @return [Set<MB::Provisioner::Base>]
      def all
        @all ||= Set.new
      end

      # Get registered provisioner class from the given ID. Return nil if no provisioner with
      # the corresponding ID is found
      #
      # @param [#to_sym] id
      #
      # @return [Class, nil]
      def get(id)
        all.find { |klass| klass.provisioner_id == id.to_sym }
      end

      # Get registered provisioner class fromt he given ID. Raise an error if no provisioner with
      # the corresponding ID is found
      #
      # @raise [ProvisionerNotRegistered] if no provisioner with the corresponding ID is found
      #
      # @return [Class]
      def get!(id)
        provisioner = get(id)

        if provisioner.nil?
          raise ProvisionerNotRegistered, "No provisioner registered with the ID: '#{id}'"
        end

        provisioner
      end

      # Return the default provisioner if one has been registered as the default
      #
      # @return [Class, nil]
      def default
        _default_id = ENV['MB_DEFAULT_PROVISIONER'] || self.default_id
        get!(_default_id) if _default_id
      end

      # Clears all of the registered Provisioners.
      #
      # @return [Set]
      #   an empty Set
      def clear!
        @default_id = nil
        @all        = Set.new
      end

      # @param [Symbol] klass
      #
      # @raise [InvalidProvisionerClass] if the class does not respond to provisioner_id
      #
      # @return [Boolean]
      def validate_provisioner_class(klass)
        unless klass.respond_to?(:provisioner_id)
          raise InvalidProvisionerClass, "Cannot register provisioner: all provisioners must respond to ':provisioner_id'"
        end

        if klass.provisioner_id.nil?
          raise InvalidProvisionerClass, "Cannot register provisioner: invalid provisioner_id '#{klass.provisioner_id}'"
        end

        true
      end
    end

    class Base
      class << self
        # The identifier for the Provisioner
        #
        # @return [Symbol]
        attr_reader :provisioner_id

        # @param [#to_sym] provisioner_id
        def register_provisioner(provisioner_id, options = {})
          @provisioner_id = provisioner_id.to_sym
          Provisioner.register(self, options)
        end

        # Validate that the return created nodes contains the expected number of nodes and the proper
        # instance types
        #
        # @param [Array<Hash>] created
        # @param [Provisioner::Manifest] manifest
        #
        # @raise [UnexpectedProvisionCount] if an unexpected amount of nodes was returned by the
        #   request to the provisioner
        def validate_create(created, manifest)
          unless created.length == manifest.node_count
            raise UnexpectedProvisionCount.new(manifest.node_count, created.length)
          end
        end
      end

      include Celluloid
      include MB::Logging
      include MB::Mixin::Services

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      # Request a provisioner to generate a set of nodes described by the given manifest
      #
      # @param [MB::Job] job
      # @param [String] env_name
      #   name of the set of nodes to be created
      # @param [MB::Provisioner::Manifest] manifest
      #   manifest describing how many and what kind of nodes to create
      # @param [MB::Plugin] plugin
      # @param [Hash] options
      #
      # @example
      #   [
      #     {
      #       instance_type: "m1.large",
      #       public_hostname: "cloud-1.riotgames.com"
      #     },
      #     {
      #       instance_type: "m1.small",
      #       public_hostname: "cloud-2.riotgames.com"
      #     }
      #   ]
      #
      # @return [Array]
      #   an array of hashes representing nodes generated of given sizes
      def up(job, env_name, manifest, plugin, options = {})
        raise AbstractFunction
      end

      # Destroy a set of provisioned nodes
      #
      # @param [MB::Job] job
      # @param [String] environment_name
      #   name of the set of nodes to destroy
      # @param [Hash] options
      #
      # @raise [MB::ProvisionError]
      #   if a caught error occurs during provisioning
      #
      # @return [Boolean]
      def down(job, environment_name, options = {})
        raise AbstractFunction
      end

      private

        # Delete an environment from Chef server
        #
        # @param [String] env_name
        #   name of the environment to remove
        def delete_environment(env_name)
          ridley.environment.delete(env_name)
        end
    end
  end
end
