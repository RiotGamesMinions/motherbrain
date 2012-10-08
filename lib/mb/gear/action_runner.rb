module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com
    # @api private
    class ActionRunner
      # @return [MotherBrain::Context]
      attr_accessor :context

      attr_reader :action

      def initialize(gear, action)
        @gear = gear
        @action = action
        @context = OpenStruct.new
      end

      def on(group_name)
        if group(group_name).nil?
          raise GroupNotFound, "Group '#{group_name}' not found"
        end

        groups.add(group_name)
        self
      end

      def groups
        context.groups ||= Set.new
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
