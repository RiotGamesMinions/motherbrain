module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
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
    end
  end
end
