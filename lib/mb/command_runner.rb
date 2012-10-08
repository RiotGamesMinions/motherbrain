module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @api private
  class CommandRunner
    attr_reader :scope

    # @return [Proc]
    attr_reader :execute

    # @param [Object] scope
    # @param [Proc] execute
    def initialize(scope, execute, *args)
      @scope = scope
      @execute = execute
      @arguments = args

      instance_eval(&execute)
    end

    def chef_run(&block)
      unless block_given?
        raise PluginSyntaxError, "Block required"
      end

      runner = scope.instance_eval(&block)
      runner.context = scope.context
      runner.run

      nodes = runner.context.groups.collect do |name|
        scope.group(name).nodes(scope.context.environment)
      end.flatten.uniq

      chef_start(nodes)
    end

    private

      def chef_start(nodes)
        nodes.each do |node|
          puts "Running Chef on #{node[:name]}"
        end
      end
  end
end
