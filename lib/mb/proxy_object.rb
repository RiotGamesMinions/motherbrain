module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module ProxyObject
    include Mixin::SimpleAttributes

    def initialize(&block)
      unless block_given?
        raise PluginSyntaxError, "Block required to evaluate ProxyObject objects"
      end

      instance_eval(&block)
    end
  end
end
