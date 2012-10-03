module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Gear
    class << self
      # @param [~MotherBrain::Gear] klass
      def register(klass)
        all.add(klass)
      end

      # @return [Set<MotherBrain::Gear>]
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

      # @return [Set]
      def clear!
        @all = Set.new
      end
    end

    extend ActiveSupport::Concern

    included do
      class_eval do
        set_keyword(self.to_s.demodulize.underscore)
        register_gear
        include RealObject
      end
    end

    module ClassMethods
      # @return [Symbol]
      attr_reader :keyword

      # @param [#to_sym] value
      def set_keyword(value)
        @keyword = value.to_sym
      end

      def register_gear
        Gear.register(self)
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  require "mb/gears/#{File.basename(path, '.rb')}"
end
