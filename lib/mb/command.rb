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

      # Run the block specified on the nodes in the groups specified.
      #
      # @param [Array] group_names groups to run on
      #
      # @option options [Integer] :any
      #   the number of nodes to run on, which nodes are chosen doesn't matter
      # @option options [Integer] :max_concurrent
      #   the number of nodes to run on at a time
      #
      # @example running on masters and slaves, only 2 of them, 1 at a time 
      #
      #   on("masters", "slaves", any: 2, max_concurrent: 1) do
      #     # actions
      #   end
      def on(*group_names, &block)
        options = group_names.last.kind_of?(Hash) ? group_names.pop : {}

        unless block_given?
          raise PluginSyntaxError, "Block required"
        end

        actions = CleanRoom.new(context, scope, &block).actions

        nodes = group_names.map { |group_name| scope.group!(group_name) }.flat_map(&:nodes).uniq

        if options[:any]
          nodes = nodes.first(options[:any])
        end
        
        options[:max_concurrent] ||= nodes.count
        nodes.each_slice(options[:max_concurrent]) do |current_nodes|
          actions.each do |action|
            action.run(current_nodes)
          end
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
