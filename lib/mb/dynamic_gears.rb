module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Dynamically create a collection instance function and element instance function
  # for retrieving all or one gears present 
  #
  # @private api
  module DynamicGears
    extend ActiveSupport::Concern

    included do
      class_eval do
        Gear.all.each do |klass|
          collection = PluginDSL::Gears.collection_name(klass)
          element = PluginDSL::Gears.element_name(klass)

          define_method(element) do |target_gear|
            send(collection).find { |gear| gear.name == target_gear }
          end

          define_method(collection) do
            attributes[collection].values
          end
        end
      end
    end
  end
end
