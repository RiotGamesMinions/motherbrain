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
            command.context.environment = environment
            command.invoke
          end
        end
    end
  end
end
