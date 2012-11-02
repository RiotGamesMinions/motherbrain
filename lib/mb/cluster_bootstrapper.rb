module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ClusterBootstrapper < RealModelBase
    attr_reader :plugin
    attr_reader :boot_tasks

    def initialize(context, plugin, &block)
      super(context)
      @plugin = plugin
      @boot_tasks = Array.new

      if block_given?
        dsl_eval(&block)
      end
    end

    def run
      # run the tasks
    end

    private

      def dsl_eval(&block)
        room = CleanRoom.new(context, self)
        room.instance_eval(&block)
        @boot_tasks = room.send(:boot_tasks)
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      # @param [MB::Context] context
      # @param [MB::Plugin, MB::Component] real_model
      def initialize(context, real_model)
        super(context, real_model)
        @boot_tasks = Array.new
      end

      def bootstrap(component, group)
        self.boot_tasks << lambda { 
          real_model.plugin.component!(component).group!(group) 
        }
      end

      def async(&block)
        room = self.class.new(context, real_model)
        room.instance_eval(&block)

        self.boot_tasks << room.boot_tasks
      end

      protected

        attr_reader :boot_tasks
    end
  end
end
