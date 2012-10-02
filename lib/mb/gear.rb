module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Gear
    class << self
      def included(base)
        base.extend(ClassMethods)
        base.set_keyword(base.to_s.demodulize.underscore)
        base.set_proxy("#{base.to_s.demodulize}Proxy")
        register(base)
      end

      def all
        @all ||= Set.new
      end

      def reload!
        ObjectSpace.each_object(::Module).each do |mod|
          if mod < MB::Gear
            register(mod)
          end
        end
      end

      def clear!
        @all = Set.new
      end

      private

        def register(klass)
          all.add(klass)
        end
    end

    module ClassMethods
      # @return [Symbol]
      attr_reader :keyword

      # @param [#to_sym] value
      def set_keyword(value)
        @keyword = value.to_sym
      end

      # @return [Class]
      def proxy
        const_get(@proxy)
      end

      # @param [String] proxy
      def set_proxy(proxy)
        @proxy = proxy
      end
    end

    include Mixin::SimpleAttributes

    def initialize(&block)
      if block_given?
        @attributes = self.class.proxy.new(&block).attributes
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  require "mb/gears/#{File.basename(path, '.rb')}"
end
