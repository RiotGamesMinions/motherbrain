module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      include Celluloid

      def provision(nodes, options = {})
        options[:with] ||= Provisioners.default
      end
    end
  end
end
