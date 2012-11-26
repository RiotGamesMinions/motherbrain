module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class BootTask
      attr_reader :id
      attr_reader :group

      def initialize(id, group)
        @id    = id
        @group = group
      end
    end
  end
end
