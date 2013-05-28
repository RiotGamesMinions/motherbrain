module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <reset@riotgames.com>
    class Routine
      # Container for a bootstrap task defined in a bootstrap routine
      #
      # @api private
      class Task
        class << self
          # Create a new bootstrap routine task from a group path
          #
          # @param [MB::Plugin] plugin
          #   the plugin to find the group in
          # @param [#to_s] group_path
          #   a string representing the path to a group in a component ("nginx::master")
          #
          # @raise [MB::PluginSyntaxError] if the group or component is not found on the plugin
          def from_group_path(plugin, group_path)
            component, group = group_path.to_s.split('::')
            group_object     = plugin.component!(component).group!(group)
            new(group_path, group_object)
          rescue ComponentNotFound, GroupNotFound => ex
            raise PluginSyntaxError, ex
          end
        end

        attr_reader :groups
        attr_reader :group_object

        # @param [String] group_name
        # @param [MB::Group] group_object
        def initialize(group_name, group_object)
          @groups       = Array(group_name)
          @group_object = group_object
        end
      end

      # @return [MB::Plugin]
      attr_reader :plugin

      # @param [MB::Plugin] plugin
      def initialize(plugin, &block)
        @plugin     = plugin
        @task_procs = Array.new

        if block_given?
          dsl_eval(&block)
        end
      end

      # Returns an array of groups or an array of an array groups representing the order in
      # which the cluster should be bootstrapped in. Groups which can be bootstrapped together
      # are contained within an array. Groups should be bootstrapped starting from index 0 of
      # the returned array.
      #
      # @return [Array<Bootstrap::Routine::Task>, Array<Array<Bootstrap::Routine::Task>>]
      def task_queue
        @task_queue ||= MB.expand_procs(task_procs)
      end

      # Checks if the routine contains a boot task for the given node group
      #
      # @param [String] node_group
      #   name for a bootstrap task to check for
      #
      # @return [Boolean]
      def has_task?(node_group, task_queue = self.task_queue)
        task_queue.find do |task|
          if task.is_a?(Array)
            has_task?(node_group, task)
          else
            task.groups.include?(node_group)
          end
        end
      end

      private

        # @return [Array<Proc>]
        attr_reader :task_procs

        def dsl_eval(&block)
          room = CleanRoom.new(self)
          room.instance_eval(&block)
          @task_procs = room.send(:task_procs)
        end

      # @author Jamie Winsor <reset@riotgames.com>
      # @api private
      class CleanRoom < CleanRoomBase
        def initialize(*args)
          super
          @task_procs = Array.new
        end

        # Add a Bootstrap::Routine::Task for bootstrapping nodes in the given node group to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     bootstrap("mysql::master")
        #   end
        #
        # @param [String] group_path
        #   a group path
        def bootstrap(group_path)
          self.task_procs.push -> { Task.from_group_path(real_model.plugin, group_path) }
        end

        # Add an array of Bootstrap::Routine::Task(s) to be executed asyncronously to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     async do
        #       bootstrap("mysql::master")
        #       bootstrap("myapp::webserver")
        #     end
        #   end
        def async(&block)
          room = self.class.new(real_model)
          room.instance_eval(&block)

          self.task_procs.push room.task_procs
        end

        protected

          # @return [Array<Proc>]
          attr_reader :task_procs
      end
    end
  end
end
