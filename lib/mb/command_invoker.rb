module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CommandInvoker
    autoload :Worker, 'mb/command_invoker/worker'

    class << self
      # @raise [Celluloid::DeadActorError] if command invoker has not been started
      #
      # @return [Celluloid::Actor(CommandInvoker)]
      def instance
        MB::Application[:command_invoker] or raise Celluloid::DeadActorError, "command invoker not running"
      end
    end

    include Celluloid
    include MB::Logging
    include MB::Mixin::Services
    include MB::Mixin::Locks

    def initialize
      log.info { "Command Invoker starting..." }
    end

    # Asynchronously invoke a command on a plugin or a component of a plugin.
    #
    # @param [String] command_name
    #   Name of the command to invoke
    #
    # @option options [String] :plugin
    # @option options [String] :component (optional)
    # @option options [String] :version (optional)
    # @option options [String] :environment
    # @option options [Array] :arguments (Array.new)
    # @option options [Boolean] :force (false)
    #
    # @return [MB::Job]
    def async_invoke(command_name, options = {})
      job = Job.new(:command)
      async(:invoke, job, command_name, options)
      job.ticket
    end

    # Find a plugin or component level which has already been loaded by a plugin.
    #
    # @param [String] command_name
    #   Name of the command to find
    # @param [String] plugin_name
    #   The name of the plugin that the command you are looking for belongs to
    #
    # @option options [String] :component (optional)
    #   Name of the component that this command belongs to. If no component name is specified then
    #   it is assumed that you are searching for a plugin level command and not a component level
    #   command.
    # @option options [String] :environment (optional)
    #   The environment the command will be executed on. The best version of the command to run on
    #   that environment will be returned. If no environment is specified the latest version of the
    #   command will be returned.
    # @option options [String] :version (optional)
    #   The specific version of the plugin you are looking for the command on
    #
    # @raise [MB::CommandNotFound]
    # @raise [MB::PluginNotFound]
    # @raise [MB::ComponentNotFound]
    # @raise [MB::EnvironmentNotFound]
    #
    # @return [MB::Command]
    def find(command_name, plugin_name, options = {})
      if options[:version]
        for_version(options[:version], command_name, plugin_name, options[:component])
      elsif options[:environment]
        for_environment(options[:environment], command_name, plugin_name, options[:component])
      else
        find_latest(command_name, plugin_name, options[:component])
      end
    end

    # Invoke a command on a plugin or a component of a plugin
    #
    # @param [MB::Job] job
    #   A job to update with progress
    # @param [String] command_name
    #   Name of the command to invoke
    #
    # @option options [String] :plugin
    # @option options [String] :component (optional)
    # @option options [String] :environment
    # @option options [String] :version (optional)
    # @option options [Array] :arguments (Array.new)
    # @option options [Boolean] :force (false)
    #
    # @raise [MB::ArgumentError]
    #
    # @return [Boolean]
    def invoke(job, command_name, options = {})
      options     = options.reverse_merge(arguments: Array.new, force: false)
      worker      = nil
      on_complete = -> { worker.terminate if worker && worker.alive? }

      job.execute(success_msg: "successfully executed command", on_complete: on_complete) do
        if options[:plugin].nil?
          raise MB::ArgumentError, "must specify a plugin that the command belongs to"
        end

        if options[:environment].nil?
          raise MB::ArgumentError, "must specify an environment to run this command on"
        end

        job.set_status("Finding environment #{options[:environment]}")
        environment_manager.find(options[:environment])

        command = find(command_name, options[:plugin], options.slice(:component, :environment, :version))
        worker  = Worker.new(command, options[:environment])

        chef_synchronize(chef_environment: options[:environment], force: options[:force], job: job) do
          worker.run(job, options[:arguments])
        end
      end
    end

    private

      # Return a plugin level or component level command from the given plugin based on
      # the arguments given.
      #
      #   * If a component name is not included it is assumed the command to return is a plugin level command.
      #   * If a component name is included it is assumed that the command to return is a component level command.
      #
      # @param [MB::Plugin] plugin
      #   Plugin to find the command on
      # @param [String] command_name
      #   Name of the command to find
      # @param [String] component_name
      #   Name of the component of the plugin that the command belongs to
      #
      # @raise [MB::CommandNotFound]
      # @raise [MB::PluginNotFound]
      # @raise [MB::ComponentNotFound]
      #
      # @return [MB::Command]
      def command_for(plugin, command_name, component_name = nil)
        if component_name.nil?
          plugin.command!(command_name)
        else
          plugin.component!(component_name).command!(command_name)
        end
      rescue PluginNotFound, CommandNotFound, ComponentNotFound => ex
        abort(ex)
      end

      # Return the latest version of a plugin or component level command the given command name, plugin name,
      # and optional component name.
      #
      # @param [String] command_name
      #   Name of the command to find
      # @param [String] plugin_name
      #   Name of the plugin the command you are looking for belongs to
      # @param [String] component_name
      #   Name of the component of the plugin that the command belongs to
      #
      # @raise [MB::CommandNotFound]
      # @raise [MB::PluginNotFound]
      # @raise [MB::ComponentNotFound]
      #
      # @return [MB::Command]
      def find_latest(command_name, plugin_name, component_name = nil)
        plugin = plugin_manager.latest(plugin_name)
        command_for(plugin, command_name, component_name)
      end

      # Return the best version of a plugin or component level command the given command name, plugin name,
      # and optional component name to use when communicating with the given environment.
      #
      # @param [String] environment_name
      #   name of the environment
      # @param [String] command_name
      #   Name of the command to find
      # @param [String] plugin_name
      #   Name of the plugin the command you are looking for belongs to
      # @param [String] component_name
      #   Name of the component of the plugin that the command belongs to
      #
      # @raise [MB::EnvironmentNotFound]
      # @raise [MB::CommandNotFound]
      # @raise [MB::PluginNotFound]
      # @raise [MB::ComponentNotFound]
      #
      # @return [MB::Command]
      def for_environment(environment_name, command_name, plugin_name, component_name = nil)
        plugin = plugin_manager.for_environment(plugin_name, environment_name)
        command_for(plugin, command_name, component_name)
      end

      # Return the specific version of a plugin or component level command the given command name, plugin name,
      # and optional component name.
      #
      # @param [String] plugin_version
      #   Version of the plugin to find the command on
      # @param [String] command_name
      #   Name of the command to find
      # @param [String] plugin_name
      #   Name of the plugin to find the command on
      # @param [String] component_name
      #   Name of the component of the plugin that the command belongs to
      #
      # @raise [MB::CommandNotFound]
      # @raise [MB::PluginNotFound]
      # @raise [MB::ComponentNotFound]
      #
      # @return [MB::Command]
      def for_version(plugin_version, command_name, plugin_name, component_name = nil)
        plugin = plugin_manager.find(plugin_name, plugin_version)

        if plugin.nil?
          abort MB::PluginNotFound.new(plugin_name, plugin_version)
        end

        command_for(plugin, command_name, component_name)
      end
  end
end
