module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @private api
  class DynamicInvoker < InvokerBase
    class << self
      # @raise [AbstractFunction] if class is not implementing {#fabricate}
      def fabricate(*args)
        raise AbstractFunction, "Class '#{self}' must implement abstract function"
      end

      protected

        # Define a new Thor command from the given {MotherBrain::Command}
        #
        # @param [MotherBrain::Command] command
        def define_command(command)
          arguments = ["environment"]

          command.execute.parameters.each do |type, parameter|
            arguments << parameter.to_s
          end

          arguments_string = arguments.join ", "
          description_string = arguments.map(&:upcase).join " "

          method_option :force,
            type: :boolean,
            default: false,
            desc: "Run command even if the environment is locked",
            aliases: "-f"
          desc("#{command.name} #{description_string}", command.description.to_s)
          instance_eval <<-RUBY
            define_method(:#{command.name}) do |#{arguments_string}|
              command.invoke(
                {
                  chef_environment: environment,
                  force: options[:force]
                },
                #{arguments_string}
              )
            end
          RUBY
        end
    end
  end
end
