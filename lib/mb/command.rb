module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Command < ContextualModel
    attr_reader :name

    def initialize(name, context, scope, &block)
      super(context)
      @name  = name
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
        @scope   = scope

        instance_eval(&execute)
      end

      def chef_run(&block)
        unless block_given?
          raise PluginSyntaxError, "Block required"
        end

        actions = CleanRoom.new(context, scope, &block).actions
        actions.map(&:run)

        nodes = actions.collect(&:nodes).flatten.uniq

        runner_options = {}.tap do |opts|
          opts[:nodes]    = nodes
          opts[:user]     = config.ssh_user
          opts[:keys]     = config.ssh_key if config.ssh_key
          opts[:password] = config.ssh_password if config.ssh_password
        end

        chef = ChefRunner.new(runner_options)
        chef.test!
        status, errors = chef.run

        if status == :error
          raise ChefRunFailure.new(errors)
        end
      end

      class CleanRoom < ContextualModel
        attr_reader :actions

        # @param [Object] scope
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
