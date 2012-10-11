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

      scope.context.runners = Array.new
      scope.instance_eval(&block)

      scope.context.runners.each { |runner| runner.run }

      nodes = scope.context.runners.collect do |runner|
        runner.nodes
      end.flatten.uniq

      runner_options = {}.tap do |opts|
        opts[:nodes] = nodes
        opts[:user] = scope.context.config.ssh_user
        opts[:keys] = scope.context.config.ssh_key if scope.context.config.ssh_key
        opts[:password] = scope.context.config.ssh_password if scope.context.config.ssh_password
      end

      chef = ChefRunner.new(runner_options)
      chef.test!
      status, errors = chef.run

      if status == :error
        raise ChefRunFailure.new(errors)
      end
    ensure
      scope.context.runners = nil
    end
  end
end
