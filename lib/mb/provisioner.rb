module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioner
    autoload :Manager, 'mb/provisioner/manager'
    autoload :Manifest, 'mb/provisioner/manifest'

    class << self
      def included(base)
        base.extend(ClassMethods)
        base.send(:include, Celluloid)
        base.send(:include, ActorUtil)
      end
    end

    module ClassMethods
      # The identifier for the Provisioner
      #
      # @return [Symbol]
      attr_reader :provisioner_id

      # @param [#to_sym] provisioner_id
      def register_provisioner(provisioner_id, options = {})
        @provisioner_id = provisioner_id.to_sym
        Provisioners.register(self, options)
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

    def up(environment, manifest)
      raise AbstractFunction
    end

    def down(environment)
      raise AbstractFunction
    end
  end
end
