module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Command < ContextualModel
    attr_reader :name

    # @param [#to_s] name
    # @param [MB::Context] context
    # @param [MB::Plugin, MB::Component] scope
    def initialize(name, context, scope, &block)
      super(context)
      @name  = name.to_s
      @scope = scope

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Run the proc stored in execute with the given arguments
    def invoke(*args)
      CommandRunner.new(context, scope, execute)
    end

    private

      attr_reader :scope

      def dsl_eval(&block)
        self.attributes = CleanRoom.new(context, &block).attributes
        self
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < ContextualModel
      def initialize(context, &block)
        super(context)

        instance_eval(&block)
      end

      # @param [String] value
      def description(value)
        set(:description, value, kind_of: String, required: true)
      end

      def execute(&block)
        value = Proc.new(&block)
        set(:execute, value, kind_of: Proc, required: true)
      end
    end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CommandRunner < ContextualModel
      attr_reader :scope

      # @param [Object] scope
      # @param [Proc] execute
      def initialize(context, scope, execute)
        super(context)
        @scope = scope

        instance_eval(&execute)
      end

      def on(group_names, options = {}, &block)
        unless block_given?
          raise PluginSyntaxError, "Block required"
        end

        unless group_names.kind_of?(Array)
          group_names = [group_names]
        end

        groups = group_names.map { |group_name| scope.group!(group_name) }
        nodes = groups.flat_map(&:nodes).uniq

        if options[:any]
          nodes = nodes.first(options[:any])
        end

        actions = CleanRoom.new(context, scope, &block).actions

        actions.each do |action|
          action.run(nodes)
        end
      end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom < ContextualModel
        attr_reader :actions

        # @param [MB::Context] context
        # @param [MB::Plugin, MB::Component] scope
        def initialize(context, scope, &block)
          super(context)
          @scope   = scope
          @actions = Array.new

          Gear.all.each do |klass|
            clean_room = self

            klass.instance_eval do
              define_method :run_action do |name|
                clean_room.actions << action = action(name)
                action
              end
            end
          end

          instance_eval(&block)
        end

        Gear.all.each do |klass|
          define_method Gear.get_fun(klass) do |gear|
            scope.send(Gear.get_fun(klass), gear)
          end
        end

        private

          attr_reader :scope
      end
    end
  end
end
