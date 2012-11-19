module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # @example valid manifest structure
    #   {
    #     "m1.large": {
    #       "activemq::master": 4,
    #       "activemq::slave": 2
    #     }
    #   }
    #
    class Manifest < JSONManifest
      class << self
        # Validate the given parameter contains a Hash or Manifest with a valid structure
        #
        # @param [Hash] manifest_hash
        #
        # @raise [InvalidProvisionManifest] if the given Hash is not well formed
        #
        # @return [Boolean]
        def validate(manifest_hash)
          super
        end
      end

      # Returns the number of nodes expected to be created by this manifest regardless of type
      #
      # @return [Integer]
      def node_count
        count = 0
        self.each_pair do |type, node_groups|
          count += node_groups.values.inject(:+)
        end

        count
      end
    end
  end
end
