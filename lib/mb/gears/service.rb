module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service < ContextualModel
      include MB::Gear
      register_gear :service

      # @return [Set<Action>]
      attr_reader :actions

      # @param [MB::Component] component
      def initialize(context, component, &block)
        super(context)

        @component = component
        @actions   = Set.new

        if block_given?
          dsl_eval(&block)
        end
      end

      # Find and return the given action
      #
      # @param [String] name
      #
      # @raise [ActionNotFound] if there is no action of the given name defined
      #
      # @return [Gear::Action]
      def action(name)
        action = get_action(name)

        if action.nil?
          raise ActionNotFound, "#{self.class.keyword} '#{self.attributes[:name]}' does not have the action '#{name}'"
        end

        action
      end
      alias_method :run_action, :action

      # Add a new action to this Service
      #
      # @param [Service::Action] new_action
      #
      # @return [Set<Action>]
      def add_action(new_action)
        unless get_action(new_action.name).nil?
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions.add(new_action)
      end

      private

        attr_reader :component

        def dsl_eval(&block)
          self.attributes = CleanRoom.new(context, self, component, &block).attributes
          self
        end

        # @param [String] name
        def get_action(name)
          self.actions.find { |action| action.name == name }
        end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom < ContextualModel
        # @param [MB::Component] component
        def initialize(context, service, component, &block)
          super(context)

          @service   = service
          @component = component
          instance_eval(&block)
        end

        # @param [String] value
        def name(value)
          set(:name, value, kind_of: String, required: true)
        end

        # @param [String] name
        def action(name, &block)
          service.add_action Action.new(context, name, component, &block)
        end

        private

          attr_reader :service
          attr_reader :component
      end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class Action < ContextualModel
        # @return [String]
        attr_reader :name
        # @return [Set<MB::Group>]
        attr_reader :groups

        # @param [String] name
        # @param [MB::Component] component
        #
        # @raise [ArgumentError] if no block is given
        def initialize(context, name, component, &block)
          unless block_given?
            raise ArgumentError, "block required for action '#{name}' on component '#{component.name}'"
          end

          super(context)
          @name      = name
          @groups    = Set.new
          @component = component
          @block     = block
          @runner    = ActionRunner.new(context, self, component)
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
          self
        end

        private

          attr_reader :component
          attr_reader :runner
          attr_reader :block

        # @author Jamie Winsor <jamie@vialstudios.com>
        # @api private
        class ActionRunner < ContextualModel
          # @param [Gear::Action] action
          # @param [MB::Component] component
          def initialize(context, action, component)
            super(context)
            @action    = action
            @component = component
          end

          # Set an environment level attribute to the given value. The key is represented
          # by a dotted path.
          #
          # @param [String] key
          # @param [Object] value
          def environment_attribute(key, value)
            MB.ui.say "Setting attribute '#{key}' to '#{value}' on #{self.environment}"

            self.chef_conn.sync do
              obj = environment.find!(self.environment)
              obj.set_override_attribute(key, value)
              obj.save
            end
          end

          # Set a node level attribute to the given value. The key is represented
          # by a dotted path.
          #
          # @param [String] key
          # @param [Object] value
          def node_attribute(key, value)
            action.nodes.each do |l_node|
              MB.ui.say "Setting attribute '#{key}' to '#{value}' on #{l_node.name}"

              self.chef_conn.sync do
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
