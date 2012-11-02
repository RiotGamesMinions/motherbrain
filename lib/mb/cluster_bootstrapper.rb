module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ClusterBootstrapper < RealModelBase
    attr_reader :plugin

    def initialize(context, plugin, &block)
      super(context)
      @plugin = plugin
      @task_procs = Array.new

      if block_given?
        dsl_eval(&block)
      end
    end

    def run(manifest)
      # run the tasks
    end

    # Returns an array of groups or an array of an array groups representing the order in 
    # which the cluster should be bootstrapped in. Groups which can be bootstrapped together
    # are contained within an array. Groups should be bootstrapped starting from index 0 of
    # the returned array.
    #
    # @return [Array<Group>, Array<Array<Group>>]
    def boot_queue
      @boot_queue ||= expand_procs(task_procs)
    end

    private

      attr_reader :task_procs

      def dsl_eval(&block)
        room = CleanRoom.new(context, self)
        room.instance_eval(&block)
        @task_procs = room.send(:task_procs)
      end

      def expand_procs(task_procs)
        task_procs.map! do |task_proc|
          if task_proc.is_a?(Array)
            expand_procs(task_proc)
          else
            task_proc.call
          end
        end
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

      def bootstrap(component, group)
        self.task_procs.push lambda {
          real_model.plugin.component!(component).group!(group) 
        }
      end

      def async(&block)
        room = self.class.new(context, real_model)
        room.instance_eval(&block)

        self.task_procs.push room.task_procs
      end

      protected

        attr_reader :task_procs
    end
  end
end
