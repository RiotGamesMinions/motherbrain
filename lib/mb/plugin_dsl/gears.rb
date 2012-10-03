module MotherBrain
  module PluginDSL
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @private api
    module Gears
      class << self
        def collection_name(klass)
          klass.keyword.to_s.pluralize.to_sym
        end

        def element_name(klass)
          klass.keyword
        end
      end

      include PluginDSL::Base
      
      Gear.all.each do |klass|
        collection = collection_name(klass)
        element    = element_name(klass)

        add_fun        = "add_#{element}".to_sym
        collection_fun = collection.to_sym
        element_fun    = element.to_sym

        define_method element_fun do |&block|
          unless block.is_a?(Proc)
            raise PluginSyntaxError, "#{element.capitalize} definition missing a required block"
          end

          send("add_#{element}", klass.new(context, &block))
        end

        define_method collection_fun do
          if instance_variable_defined?("@#{element}")
            instance_variable_get("@#{element}")
          else
            instance_variable_set("@#{element}", HashWithIndifferentAccess.new)
          end
        end
        protected collection_fun

        define_method add_fun do |obj|
          unless send(collection)[obj.name].nil?
            raise DuplicateGear, "#{element.capitalize} '#{obj.name}' already defined"
          end

          send(collection)[obj.name] = obj
        end
        private add_fun
      end

      protected

        def attributes
          attrs = {}.tap do |attrs|
            Gear.all.each do |klass|
              attribute_name = Gears.collection_name(klass)
              attrs[attribute_name] = send(attribute_name)
            end
          end

          super.merge!(attrs)
        end
    end
  end
end
