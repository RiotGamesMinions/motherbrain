module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class CommandRunner
    class InvokableComponent
      def initialize(environment, component)
        @environment = environment
        @component   = component
      end

      def invoke(command, *args)
        @component.command(command).invoke(@environment, args)
      end
    end

    def component(component_name)
      InvokableComponent.new(environment, @scope.component(component_name))
    end
    
    attr_reader :environment
    attr_reader :scope
    
    # @param [String] environment
    #   the environment to run this command on
    # @param [Object] scope
    # @param [Proc] execute
    # @param [Array] args
    def initialize(environment, scope, execute, *args)
      @environment = environment
      @scope       = scope
      @on_procs    = []
      @async       = false

      if args.any?
        curried_execute = proc { execute.call *args }
        instance_eval(&curried_execute)
      else
        instance_eval(&execute)
      end
    end

    # Run the stored procs created by on() that have not been ran yet.
    def run
      threads = []

      @on_procs.each do |on_proc|
        threads << Thread.new(on_proc) do |on_proc|
          on_proc.call
        end
      end

      threads.each(&:join)

      @on_procs = []
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

      clean_room = CleanRoom.new(scope)
      clean_room.instance_eval(&block)
      actions = clean_room.send(:actions)

      nodes = group_names.map do |name|
        scope.group!(name)
      end.flat_map do |group|
        group.nodes(environment)
      end.uniq

      if nodes.empty?
        return nil
      end

      if options[:any]
        nodes = nodes.first(options[:any])
      end

      options[:max_concurrent] ||= nodes.count
      node_groups = nodes.each_slice(options[:max_concurrent]).to_a

      @on_procs << lambda do
        node_groups.each do |nodes|
          actions.each do |action|
            action.run(environment, nodes)
          end
        end
      end

      unless async?
        run
      end
    end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      def initialize(*args)
        super
        @actions = Array.new

        Gear.all.each do |klass|
          clean_room = self

          klass.instance_eval do
            define_method :run do |*args, &block|
              clean_room.send(:actions) << action = action(*args, &block)
              action
            end
          end
        end
      end

      Gear.all.each do |klass|
        define_method Gear.get_fun(klass) do |*args|
          real_model.send(Gear.get_fun(klass), *args)
        end
      end

      protected

        attr_reader :actions
    end
  end
end
