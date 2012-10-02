module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Gear
    class << self
      def included(base)
        register(base)
      end
            
      def all
        @all ||= clear!
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
  end
end

Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  require "mb/gears/#{File.basename(path, '.rb')}"
end
