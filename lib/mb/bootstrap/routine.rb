module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Routine
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
      # @return [Array<Bootstrap::BootTask>, Array<Array<Bootstrap::BootTask>>]
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
            (task.groups & [node_group]).any?
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

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom < CleanRoomBase
        def initialize(*args)
          super
          @task_procs = Array.new
        end

        # Add a Bootstrap::BootTask for bootstrapping nodes in the given node group to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     bootstrap("mysql::master")
        #   end
        #
        # @param [String] scoped_group
        def bootstrap(scoped_group)
          self.task_procs.push -> {
            component, group = scoped_group.split('::')

            BootTask.new(scoped_group, real_model.plugin.component!(component).group!(group))
          }
        end

        # Add an array of Bootstrap::BootTasks to be executed asyncronously to the {Routine}
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
