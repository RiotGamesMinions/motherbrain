module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    class EnvironmentFactory
      include Provisioner

      register_provisioner Provisioners::DEFAULT_PROVISIONER_ID
    end
  end
end
