module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @private api
  module DynamicInvoker
    extend ActiveSupport::Concern

    module ClassMethods
      # @raise [AbstractFunction] if class is not implementing {#fabricate}
      def fabricate(*args)
        raise AbstractFunction, "Class '#{self}' must implement abstract function"
      end

      protected

        # Define a new Thor command from the given {MotherBrain::Command}
        #
        # @param [MotherBrain::Command] command
        def define_command(command)
          desc("#{command.name} ENVIRONMENT", command.description.to_s)
          define_method(command.name.to_sym) do |environment|
            assert_environment_exists(environment)

            command.send(:context).environment = environment
            command.invoke
          end
        end
    end

    protected

      def assert_environment_exists(env_name)
        context.chef_conn.environment.find!(env_name)
      rescue Ridley::Errors::HTTPNotFound
        raise EnvironmentNotFound, "Environment: '#{env_name}' not found on Chef Server"
      rescue Faraday::Error::ConnectionFailed => e
        raise ChefConnectionError, "Could not connect to Chef server (#{context.chef_conn.server_url}): #{e}"
      end
  end
end
