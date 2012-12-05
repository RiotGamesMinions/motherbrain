module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Handles provisioning of nodes and joining them to a Chef Server. Requests are
    # delegated to a provisioner of the desired type or 'Environment Factory' by
    # default.
    #
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

        # Instantiate a new provisioner based on the given options
        #
        # @param [Hash] options
        #   see {choose_provisioner} and the initializer provisioner you are attempting to
        #   initialize
        #
        # @return [~Provisioner]
        def new_provisioner(options)
          id = options.delete(:with)
          choose_provisioner(id).new(options)
        end

        # Validate that the created environment factory environment contains the expected number
        # of instance types
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
      include ActorUtil

      # Returns a SafeReturn array whose body is an array of hashes representing the nodes
      # created for the given manifest
      #
      # @example body of success
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
      # @param [#to_s] environment
      #   name of the environment to create or append to
      # @param [Provisioner::Manifest] manifest
      #   manifest of nodes to create
      # @param [MotherBrain::Plugin] plugin
      #   the plugin we are creating these nodes for
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [SafeReturn]
      def provision(environment, manifest, plugin, options = {})
        defer {
          response = safe_return(InvalidProvisionManifest) do
            Provisioner::Manifest.validate(manifest, plugin)
          end

          if response.error?
            return response
          end

          response = self.class.new_provisioner(options).up(environment.to_s, manifest)

          if response.ok?
            safe_return do
              self.class.validate_create(response.body, manifest)
              response.body
            end
          else
            response
          end
        }
      end

      # @param [#to_s] environment
      #   name of the environment to destroy
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Boolean]
      def destroy(environment, options = {})
        defer {
          self.class.new_provisioner(options).down(environment.to_s)
        }
      end
    end
  end
end
