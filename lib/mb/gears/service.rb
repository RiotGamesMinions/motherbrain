module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear

      def action(name)
        self.actions[name]
      end
    end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class ServiceProxy
      include ProxyObject

      def action(name, &block)
        if self.actions.has_key?(name)
          raise DuplicateAction, "Action '#{name}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions[name] = block
      end

      def attributes
        super.merge!(actions: self.actions)
      end

      protected

        def actions
          @actions ||= HashWithIndifferentAccess.new
        end
    end
  end
end
