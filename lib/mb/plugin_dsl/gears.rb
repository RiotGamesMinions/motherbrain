module MotherBrain
  module PluginDSL
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Gears
      include PluginDSL::Base
      
      Gear.all.each do |klass|
        define_method(klass.keyword) do |&block|
          klass.new(context, &block)
        end
      end
    end
  end
end
