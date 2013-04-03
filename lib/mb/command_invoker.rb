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
    include MB::Mixin::Locks

    def initialize
      log.info { "Command Invoker starting..." }
    end

    # Asynchronously invoke a command on a plugin or a component of a plugin
    #
    # @param [String] command_name
    #
    # @option options [String] :plugin
    # @option options [String] :component (optional)
    # @option options [String] :environment
    # @option options [Array] :arguments (Array.new)
    # @option options [Boolean] :force (false)
    #
    # @return [MB::Job]
    def async_invoke(command_name, options = {})
      job = Job.new(:invoke_command)
      async(:invoke, job, command_name, options)
      job.ticket
    end

    # Find a command to invoke
    #
    # @param [String] command_name
    #   name of the command to find
    #
    # @option options [String] :plugin (required)
    #   Plugin that the command belongs to
    # @option options [String] :component (optional)
    #   Name of the component that this command belongs to. If no component name is specified then
    #   it is assumed that you are searching for a plugin level command and not a component level
    #   command.
    # @option options [String] :environment (optional)
    #   The environment the command will be executed on. The best version of the command to run on
    #   that environment will be returned. If no environment is specified the latest version of the
    #   command will be returned.
    #
    # @raise [MB::PluginNotFound]
    # @raise [MB::ComponentNotFound]
    #
    # @return [MB::Command]
    def find_command(command_name, options = {})
      plugin_name    = options[:plugin]
      component_name = options[:component]
      environment    = options[:environment]

      if plugin_name.nil?
        raise ArgumentError
      end

      plugin = if environment
        plugin_manager.for_environment(plugin_name, environment)
      else
        plugin_manager.latest(plugin_name)
      end

      if component_name
        plugin.component!(component_name).command!(command_name)
      else
        plugin.command!(command_name)
      end
    end

    # Invoke a command on a plugin or a component of a plugin
    #
    # @param [String] command_name
    #
    # @option options [String] :plugin
    # @option options [String] :component (optional)
    # @option options [String] :environment
    # @option options [Array] :arguments (Array.new)
    # @option options [Boolean] :force (false)
    #
    # @return [MB::Job]
    def invoke(job, command_name, options = {})
      options = options.reverse_merge(arguments: Array.new, force: false)

      if options[:plugin].nil?
        raise RuntimeError, "must specify a plugin that the command belongs to"
      end

      if options[:environment].nil?
        raise RuntimeError, "must specify an environment to run this command on"
      end

      job.report_running

      job.set_status("finding environment")
      environment_manager.find(options[:environment])

      job.set_status("executing: #{command_name} with: #{options}")
      command = find_command(command_name, options.slice(:plugin, :component, :environment))

      chef_synchronize(chef_environment: options[:environment], force: options[:force], job: job) do
        job.set_status("starting command execution")
        command.invoke(options[:environment], *options[:arguments])
      end

      job.report_success("successfully executed command")
    rescue PluginNotFound, ComponentNotFound, CommandNotFound, EnvironmentNotFound => ex
      job.report_failure(ex.to_s)
    rescue => ex
      job.report_failure(ex.to_s)
      raise ex
    ensure
      job.terminate if job && job.alive?
    end
  end
end
