module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear
      register_gear :service

      attr_reader :actions

      def initialize(component, &block)
        @component = component
        @actions   = Set.new

        if block_given?
          dsl_eval(&block)
        end
      end

      def action(name)
        action = get_action(name)

        if action.nil?
          raise ActionNotFound, "#{self.class.keyword} '#{self.attributes[:name]}' does not have the action '#{name}'"
        end

        action
      end

      # @param [Service::Action] new_action
      def add_action(new_action)
        unless get_action(new_action.name).nil?
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions.add(new_action)
      end

      private

        attr_reader :component

        def dsl_eval(&block)
          self.attributes = CleanRoom.new(self, &block).attributes
          self
        end

        def get_action(name)
          self.actions.find { |action| action.name == name }
        end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom
        include Mixin::SimpleAttributes

        def initialize(component, &block)
          @component = component
          instance_eval(&block)
        end

        # @param [String] value
        def name(value)
          set(:name, value, kind_of: String, required: true)
        end

        def action(name, &block)
          component.add_action Action.new(name, component, &block)
        end

        private

          attr_reader :component
      end
    end
  end
end
