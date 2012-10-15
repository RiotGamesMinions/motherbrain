module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Action
      attr_reader :name
      attr_reader :groups

      def initialize(name, component, &block)
        @name      = name
        @groups    = Set.new
        @component = component
        @block     = block
        @runner    = ActionRunner.new(self, component)
      end

      def on(group)
        if component.group(group).nil?
          raise GroupNotFound, "Group '#{group}' not found on component '#{component.name}'"
        end

        self.groups.add(group)
        self
      end

      def nodes
        @nodes ||= groups.collect do |group|
          group.nodes
        end.flatten.uniq
      end

      def run
        runner.instance_eval(&block)
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
          puts "Setting attribute '#{key}' to '#{value}' on #{gear.environment}"
          component.chef_conn.sync do
            obj = environment.find(component.environment)
            obj.set_override_attribute(key, value)
            obj.save
          end
        end

        def node_attribute(key, value)
          action.nodes.each do |l_node|
            puts "Setting attribute '#{key}' to '#{value}' on #{l_node[:name]}"

            component.chef_conn.sync do
              obj = node.find(l_node[:name])
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
