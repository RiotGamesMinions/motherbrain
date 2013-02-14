module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class CommandInvoker
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

    def initialize
      log.info { "Command Invoker starting..." }
    end

    # Invoke a plugin level command on an environment
    #
    # @param [String] plugin_id
    # @param [String] command_id
    # @param [String] environment_id
    #
    # @option options [Array] :arguments
    #
    # @raise [EnvironmentNotFound] if the given environment does not exist
    # @raise [PluginNotFound] if a plugin of the given name is not found
    # @raise [CommandNotfound] if the plugin does not have a command matching the given name
    #
    # @return [JobTicket]
    def invoke_plugin(plugin_id, command_id, environment_id, options = {})
      options = options.reverse_merge(arguments: Array.new)
      job     = Job.new(:invoke_plugin)

      async(:_invoke_plugin_, job, plugin_id, command_id, environment_id, options)
      job.ticket
    end

    # Invoke a component level command on an environment
    #
    # @param [String] plugin_id
    # @param [String] component_id
    # @param [String] command_id
    # @param [String] environment_id
    #
    # @option options [Array] :arguments
    #
    # @raise [EnvironmentNotFound] if the given environment does not exist
    # @raise [PluginNotFound] if a plugin of the given name is not found
    # @raise [ComponentNotFound] if the plugin does not have a component matching the given name
    # @raise [CommandNotfound] if the plugin does not have a command matching the given name
    #
    # @return [JobTicket]
    def invoke_component(plugin_id, component_id, command_id, environment_id, options = {})
      options = options.reverse_merge(arguments: Array.new)
      job     = Job.new(:invoke_component)

      async(:_invoke_component_, job, plugin_id, component_id, command_id, environment_id, options)
      job.ticket
    end

    # Performs the heavy lifting for {#invoke_plugin}
    #
    # @api private
    def _invoke_plugin_(job, plugin_id, command_id, environment_id, options)
      job.report_running("determining plugin to activate for environment")
      plugin  = plugin_manager.for_environment(plugin_id, environment_id)
      command = plugin.command!(command_id)

      job.status = "starting command execution"
      command.invoke(environment_id, options[:arguments])
      job.report_success("finished executing command")
    rescue MBError => ex
      job.report_failure(ex.to_s)
    end

    # Performs the heavy lifting for {#invoke_component}
    #
    # @api private
    def _invoke_component_(job, plugin_id, component_id, command_id, environment_id, options = {})
      job.report_running("determining plugin to activate for environment")
      plugin  = plugin_manager.for_environment(plugin_id, environment_id)
      command = plugin.component!(component_id).command!(command_id)

      job.status = "starting command execution"
      command.invoke(environment_id, options[:arguments])
      job.report_success("finished executing command")
    rescue MBError => ex
      job.report_failure(ex.to_s)
    end
  end
end
