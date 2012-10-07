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

      runners = Array.new
      runners << scope.instance_eval(&block)

      nodes = runners.collect do |runner|
        runner.run
        runner.nodes
      end.flatten

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
