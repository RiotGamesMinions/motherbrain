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

          # Define a new Thor task from the given {MotherBrain::Command}
          #
          # @param [MB::Command] command
          def define_task(command)
            case command.scope
            when MB::Plugin
              plugin_name    = command.scope.name
              plugin_version = command.scope.version.to_s
              component_name = nil
            when MB::Component
              plugin_name    = command.plugin.name
              plugin_version = command.plugin.version.to_s
              component_name = command.scope.name
            else
              raise RuntimeError, "Couldn't define sub-command task. Unknown scope #{command.scope} on command #{command}"
            end

            environment = CliGateway.invoked_opts[:environment]
            arguments   = command.execute.parameters.collect { |type, parameter| parameter }

            usage = command.name
            if arguments.any?
              usage += " #{arguments.map(&:upcase).join(' ')}"
            end

            method_option :force,
              type: :boolean,
              default: false,
              desc: "Run command even if the environment is locked",
              aliases: "-f"
            desc(usage, command.description)
            define_method command.name.to_sym, ->(*arguments) do
              job = command_invoker.async_invoke(command.name,
                plugin: plugin_name,
                component: component_name,
                version: plugin_version,
                environment: environment,
                arguments: arguments,
                force: options[:force]
              )

              CliClient.new(job).display
            end
          end
        end
      end
    end
  end
end
