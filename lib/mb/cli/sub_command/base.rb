module MotherBrain
  module Cli
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      #
      # A base class that all dynamically generated SubCommands inherit from
      class Base < Cli::Base
        class << self
          alias_method :name, :namespace

          # @raise [AbstractFunction] if class is not implementing {#fabricate}
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
              # First argument is always 'environment'
              arguments = ["environment"]

              command.execute.parameters.each do |type, parameter|
                arguments << parameter.to_s
              end

              arguments_string = arguments.join(", ")
              description_string = arguments.map(&:upcase).join(" ")

              method_option :force,
                type: :boolean,
                default: false,
                desc: "Run command even if the environment is locked",
                aliases: "-f"
              desc("#{command.name} #{description_string}", command.description.to_s)
              instance_eval <<-RUBY
                define_method(:#{command.name}) do |#{arguments_string}|
                  command.invoke(
                    #{arguments_string},
                    force: options[:force]
                  )
                end
              RUBY
            end
        end
      end
    end
  end
end
