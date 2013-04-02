module MotherBrain
  module Cli
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      #
      # A base class that all dynamically generated SubCommands inherit from
      class Base < Cli::Base
        class << self
          alias_method :name, :namespace

          # @raise [AbstractFunction] if the inheriting class does not implement this function
          def fabricate(*args)
            raise AbstractFunction, "Class '#{self}' must implement abstract function"
          end

          def usage
            "#{name} [COMMAND]"
          end

          def description
            raise AbstractFunction
          end

          protected

            # Define a new Thor task from the given {MotherBrain::Command}
            #
            # @param [MotherBrain::Command] command
            def define_task(command)
              environment = CliGateway.invoked_opts[:environment]
              arguments = command.execute.parameters.collect { |type, parameter| parameter }

              method_option :force,
                type: :boolean,
                default: false,
                desc: "Run command even if the environment is locked",
                aliases: "-f"
              desc("#{command.name} #{arguments.map(&:upcase).join(' ')}", command.description)
              define_method command.name.to_sym, ->(*arguments) do
                command.invoke(environment, *arguments, force: options[:force])
              end
            end
        end
      end
    end
  end
end
