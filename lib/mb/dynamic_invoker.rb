module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module DynamicInvoker
    module ClassMethods
      def fabricate(*args)
        raise AbstractFunction
      end

      protected

        # @param [MotherBrain::Command] command
        def define_command(command)
          desc(command.name.to_s, command.description.to_s)
          define_method(command.name.to_sym) do
            command.invoke
          end
        end
    end

    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
