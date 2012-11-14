module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manifest
      attr_reader :path

      # @param [#to_s] path
      def initialize(path = nil)
        @path = path.to_s
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
    end
  end
end
