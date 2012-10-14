module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service
      include MB::Gear
      register_gear :service

      attr_reader :actions

      def initialize(component, &block)
        @component = component
        @actions     = Set.new

        if block_given?
          dsl_eval(&block)
        end
      end

      def action(id)
        action = get_action(id)

        if action.nil?
          raise ActionNotFound, "#{self.class.keyword} '#{self.attributes[:name]}' does not have the action '#{id}'"
        end

        action
      end

      # @param [Service::Action] new_action
      def add_action(new_action)
        unless get_action(new_action.id).nil?
          raise DuplicateAction, "Action '#{new_action.id}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions.add(new_action)
      end

      private

        attr_reader :component

        def dsl_eval(&block)
          self.attributes = CleanRoom.new(self, &block).attributes
          self
        end

        def get_action(id)
          self.actions.find { |action| action.id == id }
        end

      class Action
        attr_reader :id
        attr_reader :groups

        def initialize(component, id, &block)
          @component = component
          @id = id
          @groups = Set.new
          @block = block
        end

        def environment_attribute(key, value)
          puts "Setting attribute '#{key}' to '#{value}' on #{gear.environment}"
          component.chef_conn.sync do
            obj = environment.find(gear.environment)
            obj.set_override_attribute(key, value)
            obj.save
          end
        end

        def node_attribute(key, value)
          component.nodes.each do |l_node|
            puts "Setting attribute '#{key}' to '#{value}' on #{l_node[:name]}"

            component.chef_conn.sync do
              obj = node.find(l_node[:name])
              obj.set_override_attribute(key, value)
              obj.save
            end
          end
        end

        def on(group)
          if component.group(group).nil?
            raise GroupNotFound, "Group '#{group}' not found on component '#{component.name}'"
          end

          self.groups.add(group)
          self
        end

        def run
          instance_eval(&block)
        end

        private

          attr_reader :component
          attr_reader :block
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

        def action(id, &block)
          component.add_action Action.new(component, id, &block)
        end

        private

          attr_reader :component
      end
    end
  end
end
