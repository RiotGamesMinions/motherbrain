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

    class RunGroup
      # @return [Array<#run>] actions the actions to run on the nodes
      attr_accessor :actions
      # @return [Array<Array<Ridley::Node>>] node_groups the nodes to run the actions on
      attr_accessor :node_groups

      def initialize(actions, node_groups)
        @actions = actions
        @node_groups = node_groups
      end

      # Run the actions on the nodes, one group of nodes at a time.
      def run
        node_groups.each do |nodes|
          actions.each do |action|
            action.run(nodes)
          end
        end
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
        @run_groups = []
        @async = false

        instance_eval(&execute)
      end

      # Run all of the RunGroups that are stored on this instance.
      def run
        threads = []

        @run_groups.each do |run_group|
          threads << Thread.new(run_group) do |run_group|
            run_group.run
          end
        end

        threads.each(&:join)

        @run_groups = []
      end

      # Are we inside an async block?
      def async?
        @async
      end

      # Run the block asynchronously.
      def async(&block)
        @async = true
        instance_eval(&block)
        @async = false

        run
      end

      # Run the block specified on the nodes in the groups specified.
      #
      # @param [Array<String>] group_names groups to run on
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

        if nodes.empty?
          return nil
        end

        if options[:any]
          nodes = nodes.first(options[:any])
        end
        
        options[:max_concurrent] ||= nodes.count
        node_groups = nodes.each_slice(options[:max_concurrent]).to_a

        run_group = RunGroup.new(actions, node_groups)
        @run_groups << run_group

        unless async?
          run
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
