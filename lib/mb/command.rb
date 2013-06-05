module MotherBrain
  class Command
    include Chozo::VariaModel
    include MB::Mixin::Locks

    attribute :name,
      type: String,
      required: true

    attribute :description,
      type: String,
      required: true

    attribute :execute,
      type: Proc,
      required: true

    # @return [MB::Plugin, MB::Component]
    attr_reader :scope
    # @return [MB::Plugin]
    attr_reader :plugin
    # @return [Symbol]
    attr_reader :type

    # @param [#to_s] name
    # @param [MB::Plugin, MB::Component] scope
    def initialize(name, scope, &block)
      set_attribute(:name, name.to_s)
      @scope = scope

      case @scope
      when MB::Plugin
        @plugin = @scope
        @type   = :plugin
      when MB::Component
        @plugin = @scope.plugin
        @type   = :component
      else
        raise RuntimeError, "no matching command type for the given scope: #{scope}."
      end

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [String]
    def description
      _attributes_.description || "run #{name} command on #{scope.name}"
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Run the command on the given environment
    #
    # @param [MB::Job] job
    #   a job to update with progress
    # @param [String] environment
    #   the environment to invoke the command on
    # @param [Array] args
    #   additional arguments to pass to the command
    #
    # @raise [MB::ChefConnectionError] if there was an error communicating to the Chef Server
    def invoke(job, environment, *args)
      CommandRunner.new(job, environment, scope, execute, *args)
    end

    private

      def dsl_eval(&block)
        CleanRoom.new(self).instance_eval(&block)
      end

    # @api private
    class CleanRoom < CleanRoomBase
      dsl_attr_writer :description

      def execute(&block)
        real_model.execute = block
      end
    end
  end
end
