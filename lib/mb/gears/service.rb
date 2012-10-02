module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear
    end

    class ServiceProxy
      include ProxyObject
    end
  end
end
