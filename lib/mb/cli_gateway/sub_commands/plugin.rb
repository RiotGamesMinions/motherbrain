module MotherBrain
  class CliGateway
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      class Plugin < Cli::Base
        namespace :plugin

        source_root MB.app_root.join('templates')

        desc "init [PATH]", "Generate a new motherbrain plugin in the target cookbook"
        def init(path = Dir.pwd)
          metadata = File.join(path, 'metadata.rb')

          unless File.exist?(metadata)
            ui.say "#{path} is not a cookbook"
            exit(1)
          end

          cookbook = CookbookMetadata.from_file(metadata)
          config = { name: cookbook.name, groups: %w[default] }
          template 'bootstrap.json', File.join(path, 'bootstrap.json'), config
          template 'motherbrain.rb', File.join(path, 'motherbrain.rb'), config

          ui.say [
            "",
            "motherbrain plugin created.",
            "",
            "Take a look at motherbrain.rb and bootstrap.json,",
            "and then bootstrap with:",
            "",
            "  mb #{cookbook.name} bootstrap bootstrap.json",
            "",
            "To see all available commands, run:",
            "",
            "  mb #{cookbook.name} help",
            "\n"
          ].join("\n")
        end

        method_option :version,
          type: :string,
          desc: "The version of the plugin to install"
        desc "install NAME", "Install a plugin from the remote Chef server"
        def install(name)
          plugin = plugin_manager.install(name, version: options[:version])
          ui.say "Successfully installed #{plugin}"
        end

        method_option :remote,
          type: :boolean,
          default: false,
          desc: "search the remote Chef server and include plugins from the results"
        desc "list", "List all installed plugins"
        def list
          if options[:remote]
            ui.say "\n"
            ui.say "** listing local and remote plugins..."
            ui.say "\n"
          else
            ui.say "\n"
            ui.say "** listing local plugins...\n"
            ui.say "\n"
          end

          plugins = plugin_manager.list(remote: options[:remote])

          if plugins.empty?
            errmsg = "No plugins found in your Berkshelf: '#{Application.plugin_manager.berkshelf_path}'"

            if options[:remote]
              errmsg << " or on remote: '#{Application.config.chef.api_url}'"
            end

            ui.say errmsg
            exit(0)
          end

          plugins.group_by(&:name).each do |name, plugins|
            versions = plugins.collect(&:version).reverse!
            ui.say "#{name}: #{versions.join(', ')}"
          end
        end
      end
    end

    register(SubCommand::Plugin, :plugin, "plugin", "Plugin level commands")
  end
end
