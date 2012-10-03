module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module ProxyObject
    include Mixin::SimpleAttributes

    # @return [Object]
    #   the real object for this Proxy
    attr_reader :real

    # @return [MotherBrain::Context]
    attr_reader :context

    def initialize(real, &block)
      @real = real
      @context = real.context
      unless block_given?
        raise PluginSyntaxError, "Block required to evaluate DSL proxy objects"
      end

      instance_eval(&block)
    end

    # @param [String] value
    def name(value)
      set(:name, value, kind_of: String, required: true)
    end
  end
end
