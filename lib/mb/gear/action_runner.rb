module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com
    # @api private
    class ActionRunner
      attr_reader :action
      attr_reader :target_groups

      def initialize(gear, action)
        @gear = gear
        @action = action
        @target_groups = Set.new
      end

      def on(group_name)
        if group(group_name).nil?
          raise GroupNotFound, "Group '#{group_name}' not found"
        end

        target_groups.add(group_name)
        self
      end

      def nodes
        target_groups.collect do |group|
          group(group).nodes(gear.context.environment)
        end
      end

      def run(arguments = nil)
        gear.instance_eval(&action)
      end

      private

        attr_reader :gear

        def group(name)
          gear.parent.group(name)
        end
    end
  end
end
