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
            # @param [String] environment
            def define_task(command, environment)
              arguments = []

              command.execute.parameters.each do |type, parameter|
                arguments << parameter.to_s
              end

              description_string = arguments.map(&:upcase).join(" ")

              if arguments.any?
                arguments_string = arguments.join(", ")
                command_code = <<-RUBY
                  define_method(:#{command.name}) do |#{arguments_string}|
                    command.invoke(
                      environment,
                      #{arguments_string},
                      force: options[:force]
                    )
                  end
                RUBY
              else
                command_code = <<-RUBY
                  define_method(:#{command.name}) do
                    command.invoke(
                      environment,
                      force: options[:force]
                    )
                  end
                RUBY
              end

              method_option :force,
                type: :boolean,
                default: false,
                desc: "Run command even if the environment is locked",
                aliases: "-f"
              desc("#{command.name} #{description_string}", command.description.to_s)
              instance_eval command_code
            end
        end
      end
    end
  end
end
