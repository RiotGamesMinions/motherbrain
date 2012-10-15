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

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class Action
        attr_reader :name
        attr_reader :groups

        def initialize(name, component, &block)
          unless block_given?
            raise ArgumentError, "block required for action '#{name}' on component '#{component.name}'"
          end

          @name      = name
          @groups    = Set.new
          @component = component
          @block     = block
          @runner    = ActionRunner.new(self, component)
        end

        # Run this action on all of the nodes in the given group
        #
        # @param [String] group_name
        #
        # @return [self]
        #   returns the current instance to allow chaining
        def on(group_name)
          group = component.group(group_name)

          if group.nil?
            raise GroupNotFound, "Group '#{group_name}' not found on component '#{component.name}'"
          end

          self.groups.add(group)
          self
        end

        # The nodes of any group added to this Action. Only unique nodes will be
        # returned.
        #
        # @return [Array]
        def nodes
          groups.collect do |group|
            group.nodes
          end.flatten.uniq
        end

        # @return [Boolean]
        def run
          runner.instance_eval(&block)
          true
        end

        private

          attr_reader :component
          attr_reader :runner
          attr_reader :block

        # @author Jamie Winsor <jamie@vialstudios.com>
        # @api private
        class ActionRunner
          def initialize(action, component)
            @action    = action
            @component = component
          end

          def environment_attribute(key, value)
            puts "Setting attribute '#{key}' to '#{value}' on #{component.environment}"

            component.chef_conn.sync do
              obj = environment.find!(component.environment)
              obj.set_override_attribute(key, value)
              obj.save
            end
          end

          def node_attribute(key, value)
            action.nodes.each do |l_node|
              puts "Setting attribute '#{key}' to '#{value}' on #{l_node.name}"

              component.chef_conn.sync do
                obj = node.find!(l_node.name)
                obj.set_override_attribute(key, value)
                obj.save
              end
            end
          end

          private

            attr_reader :action
            attr_reader :component
        end
      end
    end
  end
end
