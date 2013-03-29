module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  class PluginManager
    class << self
      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(PluginManager)]
      def instance
        MB::Application[:plugin_manager] or raise Celluloid::DeadActorError, "plugin manager not running"
      end
    end

    include Celluloid
    include Celluloid::Notifications
    include MB::Logging
    include MB::Mixin::Services

    # @return [Pathname]
    attr_reader :berkshelf_path
    
    # Tracks when the plugin manager will attempt to load remote plugins from the Chef Server. If
    # remote loading is disabled this will return nil.
    #
    # @return [Timers::Timer, nil]
    attr_reader :eager_load_timer

    finalizer do
      log.info { "Plugin Manager stopping..." }
    end

    def initialize
      log.info { "Plugin Manager starting..." }
      @berkshelf_path = MB::Berkshelf.path
      @plugins        = Set.new

      MB::Berkshelf.init

      load_local_plugin if local_plugin?

      async_loading? ? async(:load_all) : load_all

      if eager_loading?
        @eager_load_timer = every(eager_load_interval, &method(:load_all_remote))
      end

      subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
    end

    # Add a plugin to the set of plugins
    #
    # @param [MotherBrain::Plugin] plugin
    #
    # @option options [Boolean] :force
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @return [Set<MB::Plugin>, nil]
    #   returns the set of plugins on success or nil if the plugin was not added
    def add(plugin, options = {})
      if options[:force]
        return reload(plugin)
      end

      unless find(plugin.name, plugin.version).nil?
        return nil
      end

      @plugins.add(plugin)
      plugin
    end

    # Should the plugin manager perform plugin loading operations in the background?
    #
    # @note should be disabled if running motherbrain from the CLIGateway to ensure
    #   all plugins are loaded before being accessed
    #
    # @return [Boolean]
    def async_loading?
      Application.config.plugin_manager.async_loading
    end

    # Clear list of known plugins
    #
    # @return [Set]
    def clear_plugins
      @plugins.clear
    end

    # If enabled the plugin manager will automatically discover plugins on the remote Chef Server
    # and load them into the plugin set.
    #
    # @note to change this option set it in the {Config} of {ConfigManager}
    #
    # @return [Boolean]
    def eager_loading?
      Application.config.plugin_manager.eager_loading
    end

    # The time between each poll of the remote Chef server to eagerly load discovered plugins
    #
    # @note to change this option set it in the {Config} of {ConfigManager}
    #
    # @return [Integer]
    def eager_load_interval
      Application.config.plugin_manager.eager_load_interval
    end

    # Determines if we're running inside of a cookbook with a plugin.
    #
    # @return [Boolean]
    def local_plugin?
      %w[
        metadata.rb
        motherbrain.rb
      ].all? { |file| File.exist? file }
    end

    # Load all of the plugins from the Berkshelf
    #
    # @param [Boolean] force (false)
    def load_all_local(force = false)
      Berkshelf.cookbooks(with_plugin: true).each do |path|
        load_file(path, force: force)
      end
    end

    # Load all of the plugins from the remote Chef Server. Plugins with a name and version that have
    # already been loaded will not be loaded again unless forced.
    #
    # @param [Boolean] force (false)
    def load_all_remote(force = false)
      cookbooks = ridley.cookbook.all.collect do |name, versions|
        versions.each do |version|
          unless force
            next if find(name, version, remote: false)
          end

          load_remote(name, version, force: force)
        end
      end
    end

    def load_local_plugin
      load_file '.'
    end

    # Find and return a registered plugin of the given name and version. If no version
    # attribute is specified the latest version of the plugin is returned.
    #
    # @param [String] name
    # @param [#to_s] version (nil)
    #
    # @option options [Boolean] :remote (false)
    #   search for the plugin on the remote Chef Server if it isn't found locally
    #
    # @return [Plugin, nil]
    def find(name, version = nil, options = {})
      options = options.reverse_merge(remote: false)

      list(options).sort.reverse.find do |plugin|
        if version.nil?
          plugin.name == name
        else
          plugin.name == name && plugin.version.to_s == version.to_s
        end
      end
    end

    # Determine the best version of a plugin to use when communicating to the given environment
    #
    # @param [String] plugin_id
    #   name of the plugin
    # @param [String] environment_id
    #   name of the environment
    #
    # @option options [Boolean] :remote (false)
    #   include plugins on the remote Chef Server which aren't found locally
    #
    # @raise [EnvironmentNotFound] if the given environment does not exist
    # @raise [PluginNotFound] if a plugin of the given name is not found
    #
    # @return [MB::Plugin]
    def for_environment(plugin_id, environment_id, options = {})
      options = options.reverse_merge(remote: false)
      environment = environment_manager.find(environment_id)
      constraint  = environment.cookbook_versions[plugin_id] || "> 0.0.0"

      satisfy(plugin_id, constraint, options)
    rescue MotherBrain::EnvironmentNotFound => ex
      abort ex
    end

    # @return [Array<MotherBrain::Plugin>]
    def load_all
      load_all_local
      load_all_remote if eager_loading?
    end

    # Load a plugin from a file
    #
    # @param [#to_s] path
    #
    # @option options [Boolean] :force (true)
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @return [MB::Plugin, nil]
    #   returns the loaded plugin or nil if the plugin was not loaded successfully
    def load_local(path, options = {})
      options = options.reverse_merge(force: true)
      plugin  = Plugin.from_path(path.to_s)

      add(plugin, options)
      plugin
    rescue PluginSyntaxError, PluginLoadError => ex
      log.warn { "could not load local plugin at '#{path}': #{ex}" }
      nil
    end
    alias_method :load_file, :load_local

    # Load a plugin of the given name and version from the remote Chef server
    #
    # @param [String] name
    #   name of the plugin to load
    # @param [String] version
    #   version of the plugin to load
    #
    # @option options [Boolean] :force (false)
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @return [MB::Plugin, nil]
    #   returns the loaded plugin or nil if the remote does not contain a plugin of the given
    #   name and version or if there was a failure loading the plugin
    def load_remote(name, version, options = {})
      options  = options.reverse_merge(force: false)
      resource = ridley.cookbook.find(name, version)

      unless resource && resource.has_motherbrain_plugin?
        return nil
      end

      begin
        scratch_dir   = FileSystem.tmpdir("cbplugin")
        metadata_path = File.join(scratch_dir, Plugin::JSON_METADATA_FILENAME)
        plugin_path   = File.join(scratch_dir, Plugin::PLUGIN_FILENAME)

        File.write(metadata_path, resource.metadata.to_json)

        unless resource.download_file(:root_file, Plugin::PLUGIN_FILENAME, plugin_path)
          log.warn { "error loading remote plugin: failure downloading plugin file for #{resource.name}" }
          return nil
        end

        load_file(scratch_dir, options)
      ensure
        FileUtils.rm_rf(scratch_dir)
      end
    end

    # List all versions of a plugin with the given name that are present within the local cache
    # of plugins. An empty array will be returned if no versions are present.
    #
    # @example
    #   plugin_manager.local_versions("nginx") #=> [ "1.2.3", "2.0.0", "3.1.2" ]
    #
    # @param [#to_s] name
    #   name of the plugin
    #
    # @return [Array<String>]
    def local_versions(name)
      Berkshelf.cookbooks(with_plugin: true).collect do |path|
        plugin = load_local(path)
        next if plugin.nil?

        plugin.name == name ? plugin.version.to_s : nil
      end.compact
    end

    # A set of all the registered plugins
    #
    # @option options [Boolean] :remote (false)
    #   eargly search for plugins on the remote Chef server and include them in the returned list
    #
    # @return [Set<Plugin>]
    def list(options = {})
      options = options.reverse_merge(remote: false)

      if options[:remote]
        load_all_remote
      end

      @plugins
    end

    # Remove and Add the given plugin from the set of plugins
    #
    # @param [MotherBrain::Plugin] plugin
    def reload(plugin)
      remove(plugin)
      add(plugin)
    end

    # Reload plugins from Chef Server and from the Berkshelf
    #
    # @return [Array<MotherBrain::Plugin>]
    def reload_all
      clear_plugins
      load_all
    end

    # Reload plugins from the Berkshelf
    #
    # @return [Array<MotherBrain::Plugin>]
    def reload_local
      load_all_local(true)
    end

    # Remove the given plugin from the set of plugins
    #
    # @param [MotherBrain::Plugin] plugin
    def remove(plugin)
      @plugins.delete(plugin)
    end

    # Return the best version of the plugin to use for the given constraint
    #
    # @param [String] plugin_name
    #   name of the plugin
    # @param [String, Solve::Constraint] constraint
    #   constraint to satisfy
    #
    # @option options [Boolean] :remote (false)
    #   include plugins on the remote Chef Server which aren't found locally
    #
    # @raise [PluginNotFound] if a plugin of the given name which satisfies the given constraint
    #   is not found
    #
    # @return [MB::Plugin]
    def satisfy(plugin_name, constraint, options = {})
      options    = options.reverse_merge(remote: false)
      constraint = Solve::Constraint.new(constraint)

      # Optimize for equality operator. Don't need to find all of the versions if
      # we only care about one.
      version = if constraint.operator == "="
        constrained_version = constraint.version.to_s
        if options[:remote]
          load_remote(plugin_name, constrained_version)
        end
        constrained_version
      else
        graph = Solve::Graph.new
        versions(plugin_name, options[:remote]).each do |version|
          graph.artifacts(plugin_name, version)
        end

        solution = Solve.it!(graph, [[plugin_name, constraint]])
        solution[plugin_name]
      end

      # don't search the remote for the plugin again; we would have already done that by
      # calling versions() and including our options.
      find(plugin_name, version, remote: false)
    rescue Solve::Errors::NoSolutionError
      abort PluginNotFound.new(plugin_name, constraint)
    end

    # List all of the versions of the plugin of the given name
    #
    # @param [#to_s] name
    #   name of the plugin
    # @param [Boolean] remote (false)
    #   include plugins on the remote Chef server in the results
    #
    # @raise [PluginNotFound] if a plugin of the given name has no versions loaded
    #
    # @return [Array<String>]
    def versions(name, remote = false)
      all_versions = local_versions(name)

      if remote
        all_versions += remote_versions(name)
      end
      
      if all_versions.empty?
        abort PluginNotFound.new(name)
      end

      all_versions
    end

    # List all versions of a plugin with the given name that are present on the remote Chef
    # server. An empty array will be returned if no versions are present.
    #
    # @example
    #   plugin_manager.remote_versions("nginx") #=> [ "1.2.3", "2.0.0", "3.1.2" ]
    #
    # @param [#to_s] name
    #   name of the plugin
    #
    # @return [Array<String>]
    def remote_versions(name)
      chef_connection.cookbook.versions(name).collect do |version|
        load_remote(name, version)
      end.compact
    rescue Ridley::Errors::HTTPNotFound
      []
    end

    protected

      def reconfigure(_msg, config)
        log.debug { "[Plugin Manager] received new configuration" }

        unless Berkshelf.path == self.berkshelf_path
          log.debug { "[Plugin Manager] The location of the Berkshelf has changed; reloading plugins" }

          @berkshelf_path = Berkshelf.path
          MB::Berkshelf.init
          reload_all
        end
      end
  end
end
