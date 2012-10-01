module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module DSLProxy
    include Mixin::SimpleAttributes

    def initialize(&block)
      unless block_given?
        raise "NO BLOCK BRO"
      end

      instance_eval(&block)
    end
  end
end
