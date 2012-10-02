module MotherBrain
  module PluginDSL
    # @author Jamie Winsor <jamie@vialstudios.com>
    module Gears
      Gear.all.each do |klass|
        define_method(klass.keyword) do |&block|
          klass.new(&block)
        end
      end
    end
  end
end
