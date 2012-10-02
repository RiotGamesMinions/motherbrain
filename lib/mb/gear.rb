module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Gear
    class << self
      def included(base)
        base.extend(ClassMethods)
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
      def keyword
        @keyword ||= self.class.to_s.underscore.to_sym
      end

      # @param [#to_sym] value
      def set_keyword(value)
        @keyword = value.to_sym
      end
    end

    include Mixin::SimpleAttributes

    def initialize(&block)
      # do stuff
    end
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  require "mb/gears/#{File.basename(path, '.rb')}"
end
