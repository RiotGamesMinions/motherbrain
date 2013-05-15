module MotherBrain
  class CliGateway
    module SubCommand
      # @author Jamie Winsor <reset@riotgames.com>
      class Plugin < Cli::Base
        namespace :plugin

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
