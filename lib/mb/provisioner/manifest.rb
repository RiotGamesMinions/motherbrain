module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manifest
      class << self
        def from_file(path)
          path = File.expand_path(path)
          data = File.read(path)
          new(path).from_json(data)
        end

        def validate(manifest_hash)
          true
        end
      end

      attr_reader :path
      attr_reader :attributes

      # @param [#to_s] path
      def initialize(path = nil)
        @path = path.to_s
        @attributes = Hash.new
      end

      def save
        if self.path.nil?
          raise InternalError, "Cannot save manifest without a destination. Set the 'path' attribute on your object."
        end

        FileUtils.mkdir_p(File.dirname(self.path))
        File.open(self.path, 'w+') do |f|
          f.write(self.to_json(pretty: true))
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
