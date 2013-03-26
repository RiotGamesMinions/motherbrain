module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <reset@riotgames.com>
    class BootTask
      attr_accessor :groups
      attr_reader :group_object

      def initialize(groups, group_object)
        @groups = Array(groups)
        @group_object = group_object
      end
    end
  end
end
