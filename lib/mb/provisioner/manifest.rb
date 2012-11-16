module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manifest
      class << self
        # @param [#to_s] path
        #
        # @return [Provisioner::Manifest]
        def from_file(path)
          path = File.expand_path(path.to_s)
          data = File.read(path)
          new(path).from_json(data)
        end

        # Validate a Hash representing a provisioner manifest
        #
        # @param [Hash] manifest_hash
        #
        # @raise [InvalidProvisionManifest] if the given Hash is not well formed
        #
        # @return [Boolean]
        def validate(manifest_hash)
          unless manifest_hash.is_a?(Hash)
            raise InvalidProvisionManifest, "Provisioner manifest must be a Hash"
          end

          true
        end
      end

      # return [String]
      attr_reader :path

      # @return [Hash]
      attr_reader :attributes

      # @param [#to_s] path
      def initialize(path = nil)
        @path       = path.to_s
        @attributes = Hash.new
      end

      def save
        unless self.path.present?
          raise InternalError, "Cannot save manifest without a destination. Set the 'path' attribute on your object."
        end

        FileUtils.mkdir_p(File.dirname(self.path))
        File.open(self.path, 'w+') do |f|
          f.write(MultiJson.dump(self.attributes, pretty: true))
        end

        self
      end

      def from_json(json, options = {})
        attributes = MultiJson.decode(json, options)
        self.class.validate(attributes)
        @attributes = attributes

        self
      end
    end
  end
end
