module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    class EnvironmentFactory
      include Provisioner

      register_provisioner :environment_factory, default: true
    end
  end
end
