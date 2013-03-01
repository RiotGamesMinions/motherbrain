module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
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

    # @param [#to_s] name
    # @param [MB::Plugin, MB::Component] scope
    def initialize(name, scope, &block)
      set_attribute(:name, name.to_s)
      @scope = scope

      if block_given?
        dsl_eval(&block)
      end
    end

    # @return [Symbol]
    def id
      self.name.to_sym
    end

    # Run the command on the given environment
    #
    # @param [String] environment
    #   the environment to invoke the command on
    # @param [Array] args
    #
    # @raise [MB::EnvironmentNotFound] if the target environment does not exist
    # @raise [MB::ChefConnectionError] if there was an error communicating to the Chef Server
    def invoke(environment, *args)
      options = args.last.is_a?(Hash) ? args.pop : Hash.new
      options[:chef_environment] = environment

      unless Application.ridley.environment.find(environment)
        raise EnvironmentNotFound, "Environment: '#{environment}' not found on '#{Application.ridley.server_url}'"
      end

      chef_synchronize(options) do
        CommandRunner.new(environment, scope, execute, *args)
      end
    rescue Faraday::Error::ClientError, Ridley::Errors::RidleyError => e
      raise ChefConnectionError, "Could not connect to Chef server '#{Application.ridley.server_url}': #{e}"
    end

    private

      attr_reader :scope

      def dsl_eval(&block)
        CleanRoom.new(self).instance_eval(&block)
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      dsl_attr_writer :description

      def execute(&block)
        real_model.execute = block
      end
    end
  end
end
