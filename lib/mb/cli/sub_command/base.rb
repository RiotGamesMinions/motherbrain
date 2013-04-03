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
            plugin_name    = command.plugin
            plugin_version = command.plugin.version.to_s
            component_name = nil

            if command.type == :component
              component_name = command.scope.name
            end

            environment  = CliGateway.invoked_opts[:environment]
            execute_args = command.execute.parameters.collect { |type, parameter| parameter }

            usage = command.name
            if execute_args.any?
              usage += " #{execute_args.map(&:upcase).join(' ')}"
            end

            method_option :force,
              type: :boolean,
              default: false,
              desc: "Run command even if the environment is locked",
              aliases: "-f"
            desc(usage, command.description)
            define_method command.name.to_sym, ->(*task_args) do
              job = command_invoker.async_invoke(command.name,
                plugin: plugin_name,
                component: component_name,
                version: plugin_version,
                environment: environment,
                arguments: task_args,
                force: options[:force]
              )

              display_job(job)
            end
          end
        end
      end
    end
  end
end
