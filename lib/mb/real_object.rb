module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module RealObject
    extend ActiveSupport::Concern

    included do
      class_eval do
        set_proxy("#{self}Proxy")
        include Mixin::SimpleAttributes
      end
    end

    module ClassMethods
      # @return [Class]
      #   the proxy object that the real object will get it's bound attributes from
      def proxy
        @proxy.constantize
      end

      # Override the proxy class to get bound attributes from
      #
      # @param [String] proxy
      def set_proxy(proxy)
        @proxy = proxy
      end
    end

    # @return [MotherBrain::Context]
    attr_reader :context

    # @return [Object]
    #   the parent of the nested object in a plugin tree
    attr_reader :parent

    # @param [MotherBrain::Context] context
    def initialize(context, &block)
      @context = context
      @parent = context.parent
      if block_given?
        @attributes = self.class.proxy.new(self, &block).attributes
      end
    end
  end
end
