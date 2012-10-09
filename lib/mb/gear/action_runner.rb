module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com
    # @api private
    class ActionRunner
      attr_reader :action
      attr_reader :groups

      def initialize(gear, action)
        @gear = gear
        @action = action
        @groups = Set.new
      end

      def on(group_name)
        if group(group_name).nil?
          raise GroupNotFound, "Group '#{group_name}' not found"
        end

        groups.add(group_name)
        self
      end

      def run
        gear.context.nodes = self.nodes
        gear.instance_eval(&action)
      ensure
        gear.context.nodes = nil
      end

      def nodes
        @nodes ||= groups.collect do |group|
          group(group).nodes(gear.context.environment)
        end.flatten.uniq
      end

      private

        attr_reader :gear

        def group(name)
          gear.parent.group(name)
        end
    end
  end
end
