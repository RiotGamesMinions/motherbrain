require 'motherbrain'
require 'erb'

module MB
  class CliGateway
    def self.basename
      "`mb`"
    end
  end

  class ManHelper
    def self.generate(template_path="./man/man.1.ronn.erb",output_path="./man/man.1.ronn")
      commands = []
      extended_commands = []

      shell = Thor::Shell::Basic.new

      metadata = MB::CookbookMetadata.new
      metadata.name = "plugin"
      metadata.version = Solve::Version.new("1.0.0")

      plugin = MB::Plugin.new(metadata)

      plugin.bootstrap_routine = MB::Bootstrap::Routine.new(plugin)

      subcmd = MB::Cli::SubCommand::Plugin.fabricate(plugin)
      def subcmd.basename
        "`mb` `<plugin>`"
      end

      banner_proc = lambda { |klass, command_name|
        klass.instance_eval do
          meth = normalize_command_name(command_name)
          command = all_commands[meth]
          banner(command)
        end
      }

      documentation_proc = lambda { |klass, command_name|
        klass.instance_eval do
          meth = normalize_command_name(command_name)
          command = all_commands[meth]
          [banner(command), command.description, command.long_description, command.options]
        end
      }

      MB::CliGateway.commands.each do |command|
        commands << banner_proc.call(MB::CliGateway, command[0])
        extended_commands << documentation_proc.call(MB::CliGateway, command[0])
      end

      subcmd.commands.each do |command|
        commands << banner_proc.call(subcmd, command[0])
        extended_commands << documentation_proc.call(subcmd, command[0])
      end

      class_options = MB::CliGateway.class_options

      template = ERB.new(File.read(File.expand_path(template_path)), nil, '-')
      File.open(output_path, 'w') do |file|
        file.puts template.result(binding)
      end
    end
  end
end
