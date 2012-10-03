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
      def proxy
        @proxy.constantize
      end

      # @param [String] proxy
      def set_proxy(proxy)
        @proxy = proxy
      end
    end

    attr_reader :context

    def initialize(context, &block)
      @context = context
      if block_given?
        @attributes = self.class.proxy.new(context, &block).attributes
      end
    end
  end
end
