module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Routine < RealModelBase
      class BootTask < Struct.new(:id, :group); end

      # @return [MB::Plugin]
      attr_reader :plugin

      # @param [MB::Context] context
      # @param [MB::Plugin] plugin
      def initialize(context, plugin, &block)
        super(context)
        @plugin = plugin
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
      # @return [Array<BootTask>, Array<Array<BootTask>>]
      def task_queue
        @task_queue ||= MB.expand_procs(task_procs)
      end

      # Checks if the routine contains a boot task for the given node group
      #
      # @param [String] node_group
      #   name for a bootstrap task to check for
      #
      # @return [Boolean]
      def has_task?(node_group)
        !task_queue.find do |task|
          if task.is_a?(Array)
            task.find { |task | task.id == node_group }
          else
            task.id == node_group
          end
        end.nil?
      end

      private

        # @return [Array<Proc>]
        attr_reader :task_procs

        def dsl_eval(&block)
          room = CleanRoom.new(context, self)
          room.instance_eval(&block)
          @task_procs = room.send(:task_procs)
        end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom < CleanRoomBase
        # @param [MB::Context] context
        # @param [MB::Plugin, MB::Component] real_model
        def initialize(context, real_model)
          super(context, real_model)
          @task_procs = Array.new
        end

        # Add a BootTask for bootstrapping nodes in the given node group to the {Routine}
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

        # Add an array of BootTasks to be executed asyncronously to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     async do
        #       bootstrap("mysql::master")
        #       bootstrap("myapp::webserver")
        #     end
        #   end
        def async(&block)
          room = self.class.new(context, real_model)
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
