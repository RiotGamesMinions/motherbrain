module MotherBrain
  module Cli
    # Generates SubCommands for Thor from motherbrain plugins or pieces of motherbrain plugins
    module SubCommand
      autoload :Component, 'mb/cli/sub_command/component'
      autoload :Plugin, 'mb/cli/sub_command/plugin'

      class << self
        # Generate a new SubCommand for Thor from a motherbrain plugin or component
        #
        # @param [MB::Plugin, MB::Component] object
        #
        # @raise [ArgumentError]
        #
        # @return [SubCommand::Plugin, SubCommand::Component]
        def new(object)
          case object
          when MB::Plugin
            SubCommand::Plugin.fabricate(object)
          when MB::Component
            SubCommand::Component.fabricate(object)
          else
            raise ::ArgumentError, "don't know how to fabricate a subcommand for a '#{object.class}'"
          end
        end
      end

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
            plugin_name    = command.plugin.name
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
            method_option :only,
              type: :array,
              default: nil,
              desc: "Run command only on the given hostnames or IPs",
              aliases: "-o"
            desc(usage, command.description)
            define_method command.name.to_sym, ->(*task_args) do
              job = command_invoker.async_invoke(command.name,
                plugin: plugin_name,
                component: component_name,
                version: plugin_version,
                environment: environment,
                arguments: task_args,
                force: options[:force],
                node_filter: options[:only]
              )

              display_job(job)
            end
          end
        end
      end
    end
  end
end
