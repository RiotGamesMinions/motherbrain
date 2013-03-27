module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CommandRunner
    # @return [String]
    attr_reader :environment
    # @return [MB::Plugin, MB::Component]
    attr_reader :scope

    # @param [String] environment
    #   environment to run this command on
    # @param [MB::Plugin, MB::Component] scope
    #   scope to execute this command in.
    #
    #   * executing the command in the scope of an entire plugin will give you easy access to
    #     component commands and other plugin level commands
    #   * executing the command in the scope of a component will give you easy access to the
    #     other commands available in that component
    # @param [Proc] execute
    #   the code to execute when the command runner is run
    #
    #   @example
    #     proc {
    #       on("some_nodes") { service("nginx").run("stop") }
    #     }
    # @param [Array] args
    #   any additional arguments to pass to the execution block
    def initialize(environment, scope, execute, *args)
      @environment = environment
      @scope       = scope
      @on_procs    = []
      @async       = false

      if args.any?
        curried_execute = proc { execute.call(*args) }
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
    #
    # @return [Boolean]
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

    # Select a component for the purposes of invoking a command.
    # NB: returns a proxy object
    #
    # @param [String] component_name the name of the component you want to
    #    invoke a command on
    # @return [InvokableComponent] proxy for the actual component,
    #    only useful if you call #invoke on it
    def component(component_name)
      InvokableComponent.new(environment, scope.component(component_name))
    end

    def command(command_name)
      scope.command!(command_name).invoke(environment)
    end

    # @author Jamie Winsor <reset@riotgames.com>
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

        # @param [Fixnum] seconds
        def wait(seconds)
          Celluloid.sleep(seconds)
        end
    end

    # Proxy for invoking components in the DSL
    #
    # @author Michael Ivey <michael.ivey@riotgames.com>
    # @api private
    class InvokableComponent
      attr_reader :environment
      attr_reader :component

      # @param [String] environment the environment on which to
      #   eventually invoke a command
      # @param [Component] component the component we'll be invoking
      def initialize(environment, component)
        @environment = environment
        @component   = component
      end

      # @param [String] command the command to invoke in the component
      # @param [Array] args additional arguments for the command
      def invoke(command, *args)
        component.invoke(environment, command, args)
      end
    end
  end
end
