module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      class << self
        # Returns a provisioner for the given ID. The default provisioner will be returned
        # if nil is provided
        #
        # @param [#to_sym, nil] id
        #
        # @raise [ProvisionerNotRegistered] if no provisioner is registered with the given ID
        #
        # @return [Class]
        def choose_provisioner(id)
          id.nil? ? Provisioners.default : Provisioners.get!(id)
        end

        # Validate that the created environment factory environment contains the expected number
        # of instance types
        #
        # @param [Array<Hash>] created
        # @param [Provisioner::Manifest] manifest
        #
        # @raise [UnexpectedProvisionCount] if an unexpected amount of nodes was returned by the
        #   request to the provisioner
        #
        # @return [Boolean]
        def validate_create(created, manifest)
          unless created.length == manifest.node_count
            raise UnexpectedProvisionCount.new(manifest.node_count, created.length)
          end

          true
        end
      end

      include Celluloid

      # @example value of future
      #   {
      #     "activemq::master" => [
      #       "amq1.riotgames.com",
      #       "amq2.riotgames.com",
      #       "amq3.riotgames.com",
      #       "amq4.riotgames.com"
      #     ],
      #     "activemq::slave" => [
      #       "amqs1.riotgames.com",
      #       "amqs2.riotgames.com"
      #     ]
      #   }
      #
      # @param [String] environment
      # @param [Hash] manifest
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Array]
      def provision(environment, manifest, options = {})
        provisioner_klass = self.class.choose_provisioner(options[:with])
        provisioner       = provisioner_klass.new(options)

        status, body = response = provisioner.up(environment, manifest)

        if status == :ok
          self.class.validate_create(body)
        end

        response
      end

      # @param [String] environment
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Boolean]
      def destroy(environment, options = {})
        provisioner_klass = self.class.choose_provisioner(options[:with])
        provisioner       = provisioner_klass.new(options)

        provisioner.down(environment)
      end
    end
  end
end
