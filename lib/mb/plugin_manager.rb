module MotherBrain
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

    finalizer :finalize_callback

    def initialize
      log.debug { "Plugin Manager starting..." }
      @berkshelf_path = MB::Berkshelf.path
      @plugins        = Set.new

      MB::Berkshelf.init

      async_loading? ? async(:load_all) : load_all

      if eager_loading?
        @eager_load_timer = every(eager_load_interval, &method(:load_all_remote))
      end

      subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
    end

    # Add a plugin to the set of plugins
    #
    # @param [MB::Plugin] plugin
    #
    # @option options [Boolean] :force
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @return [MB::Plugin, nil]
    #   returns the set of plugins on success or nil if the plugin was not added
    def add(plugin, options = {})
      if options[:force]
        remove(plugin)
      end

      if find(plugin.name, plugin.version, remote: false)
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

    # Load all of the plugins from the Berkshelf
    #
    # @option options [Boolean] :force (false)
    def load_all_installed(options = {})
      options = options.reverse_merge(force: false)

      installed_cookbooks.each do |path|
        load_installed(path, options)
      end
    end

    # Load all of the plugins from the remote Chef Server. Plugins with a name and version that have
    # already been loaded will not be loaded again unless forced.
    #
    # @option options [String] :name
    # @option options [Boolean] :force (false)
    def load_all_remote(options = {})
      options = options.reverse_merge(force: false)

      if options[:name].present?
        remote_cookbook_versions(options[:name]).collect do |version|
          load_remote(options[:name], version, options)
        end
      else
        [].tap do |remotes|
          remote_cookbooks.each do |name, versions|
            versions.each { |version| remotes << future(:load_remote, name, version, options) }
          end
        end.map(&:value)
      end
    end

    # Find and return a registered plugin of the given name and version. If no
    # version attribute is specified the latest version of the plugin is
    # returned.
    #
    # @param [String] name
    #   name of the plugin
    # @param [#to_s] version
    #   version of the plugin to find
    #
    # @option options [Boolean] :remote (false)
    #   search for the plugin on the remote Chef Server if it isn't installed
    #
    # @return [MB::Plugin, nil]
    def find(name, version = nil, options = {})
      options = options.reverse_merge(remote: false)

      return latest(name, options) unless version

      installed = @plugins.find { |plugin| plugin.name == name && plugin.version.to_s == version.to_s }

      return installed if installed

      if options[:remote]
        remote = load_remote(name, version.to_s)
        return remote if remote
      end

      nil
    end

    # Determine the best version of a plugin to use when communicating to the given environment
    #
    # @param [String] plugin_id
    #   name of the plugin
    # @param [String] environment_id
    #   name of the environment
    #
    # @option options [Boolean] :remote (false)
    #   include plugins on the remote Chef Server which aren't installed
    #
    # @raise [EnvironmentNotFound] if the given environment does not exist
    # @raise [PluginNotFound] if a plugin of the given name is not found
    #
    # @return [MB::Plugin]
    def for_environment(plugin_id, environment_id, options = {})
      options = options.reverse_merge(remote: false)
      environment = environment_manager.find(environment_id)
      constraint  = environment.cookbook_versions[plugin_id] || ">= 0.0.0"

      satisfy(plugin_id, constraint, options)
    rescue MotherBrain::EnvironmentNotFound => ex
      abort ex
    end

    # Finds the plugin for the cookbook specified in the run list entry
    #
    # @param [String] run_list_entry
    #   Chef standard run list entry
    # @param [String] environment
    #   name of the environment
    #
    # @return [MB::Plugin]
    def for_run_list_entry(run_list_entry, environment = nil, options = {})
      item = MotherBrain::Chef::RunListItem.new(run_list_entry)
      if item.version
        # version will be defined in run list entries such as
        # recipe[foo::server@1.1.2], which takes precidence over the
        # environment.
        find(item.cookbook_name, item.version, options)
      elsif !environment.nil?
        for_environment(item.cookbook_name, environment, options)
      else
        find(item.cookbook_name, nil, options)
      end
    end

    # @param [String] name
    #   name of the plugin
    # @param [#to_s] version
    #   version of the plugin to find
    def has_plugin?(name, version)
      !find(name, version).nil?
    end

    # Download and install the cookbook containing a motherbrain plugin matching the
    # given name and optional version into the user's Berkshelf.
    #
    # @param [String] name
    #   Name of the plugin
    # @param [#to_s] version
    #   The version of the plugin to install. If left blank the latest version will be installed
    #
    # @return [MB::Plugin]
    #
    # @raise [MB::PluginNotFound]
    def install(name, version = nil)
      unless plugin = find(name, version, remote: true)
        abort MB::PluginNotFound.new(name, version)
      end

      chef_connection.cookbook.download(plugin.name, plugin.version, install_path_for(plugin))
      reload(plugin)
    end

    # The filepath that a plugin would be or should be installed to
    #
    # @param [MB::Plugin] plugin
    #
    # @return [Pathname]
    def install_path_for(plugin)
      Berkshelf.cookbooks_path.join("#{plugin.name}-#{plugin.version}")
    end

    # Return most current version of the plugin of the given name
    #
    # @param [String] name
    #   name of the plugin
    #
    # @option options [Boolean] :remote (false)
    #   include plugins on the remote Chef server which haven't been cached or installed
    #
    # @return [MB::Plugin, nil]
    def latest(name, options = {})
      options = options.reverse_merge(remote: false)

      potentials = list(name: name, remote: false).map(&:version)
      potentials += remote_cookbook_versions(name) if options[:remote]
      potentials = potentials.collect { |version| Semverse::Version.new(version) }.uniq.sort.reverse

      potentials.find do |version|
        found = find(name, version.to_s, options.slice(:remote))
        return found if found
      end

      nil
    end

    # @return [Array<MotherBrain::Plugin>]
    def load_all
      load_all_installed
      load_all_remote if eager_loading?
    end

    # Load a plugin from a file
    #
    # @param [#to_s] path
    #
    # @option options [Boolean] :force (true)
    #   load a plugin even if a plugin of the same name and version is already loaded
    # @option options [Boolean] :allow_failure (true)
    #   allow for loading failure
    #
    # @return [MB::Plugin, nil]
    #   returns the loaded plugin or nil if the plugin was not loaded successfully
    def load_installed(path, options = {})
      options = options.reverse_merge(force: true, allow_failure: true)
      load_file(path, options)
    rescue PluginSyntaxError, PluginLoadError => ex
      err_msg = "could not load plugin at '#{path}': #{ex.message}"
      options[:allow_failure] ? log.debug(err_msg) : abort(PluginLoadError.new(err_msg))
      nil
    end

    # Load a plugin of the given name and version from the remote Chef server
    #
    # @param [String] name
    #   name of the plugin to load
    # @param [String] version
    #   version of the plugin to load
    #
    # @option options [Boolean] :force (false)
    #   load a plugin even if a plugin of the same name and version is already loaded
    # @option options [Boolean] :allow_failure (true)
    #   allow for loading failure
    #
    # @raise [PluginSyntaxError]
    # @raise [PluginLoadError]
    #
    # @return [MB::Plugin, nil]
    #   returns the loaded plugin or nil if the remote does not contain a plugin of the given
    #   name and version or if there was a failure loading the plugin
    def load_remote(name, version, options = {})
      options  = options.reverse_merge(force: false, allow_failure: true)
      resource = ridley.cookbook.find(name, version)

      return unless resource && resource.has_motherbrain_plugin?

      begin
        scratch_dir   = FileSystem.tmpdir("cbplugin")
        metadata_path = File.join(scratch_dir, CookbookMetadata::JSON_FILENAME)
        plugin_path   = File.join(scratch_dir, Plugin::PLUGIN_FILENAME)

        File.write(metadata_path, resource.metadata.to_json)

        unless resource.download_file(:root_file, Plugin::PLUGIN_FILENAME, plugin_path)
          raise PluginLoadError, "failure downloading plugin file for #{resource.name}"
        end

        load_file(scratch_dir, options)
      rescue PluginSyntaxError, PluginLoadError => ex
        err_msg = "could not load remote plugin #{name} (#{version}): #{ex.message}"
        options[:allow_failure] ? log.debug(err_msg) : abort(PluginLoadError.new(err_msg))
        nil
      ensure
        FileUtils.rm_rf(scratch_dir)
      end
    end

    # List all installed versions of a plugin with the given name of plugins. An empty
    # array will be returned if no versions of a plugin are installed.
    #
    # @example
    #   plugin_manager.installed_versions("nginx") #=> [ "1.2.3", "2.0.0", "3.1.2" ]
    #
    # @param [#to_s] name
    #   name of the plugin
    #
    # @return [Array<String>]
    def installed_versions(name)
      installed_cookbooks.collect do |path|
        plugin = load_installed(path)
        next unless plugin

        if plugin.name == name
          plugin.version.to_s
        end
      end.compact
    end

    # A set of all the registered plugins
    #
    # @option options [String] :name
    #   filter the results to include only plugins of the given name
    # @option options [Boolean] :remote (false)
    #   eargly search for plugins on the remote Chef server and include them in the returned list
    #
    # @return [Array<MB::Plugin>]
    def list(options = {})
      options = options.reverse_merge(remote: false)

      if options[:remote]
        load_all_remote(options.slice(:name))
      end

      result = options[:name].nil? ? @plugins : @plugins.select { |plugin| plugin.name == options[:name] }
      result.sort.reverse
    end

    # Remove and Add the given plugin from the set of plugins
    #
    # @param [MB::Plugin] plugin
    def reload(plugin)
      add(plugin, force: true)
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
    def reload_installed
      load_all_installed(force: true)
    end

    # Remove the given plugin from the set of plugins
    #
    # @param [Set<MB::Plugin>] plugin
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
    #   include plugins on the remote Chef Server which aren't installed
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
      if constraint.operator == "="
        find(plugin_name, constraint.version, options.slice(:remote))
      elsif constraint.to_s == ">= 0.0.0"
        latest(plugin_name, options.slice(:remote))
      else
        graph = Solve::Graph.new
        versions(plugin_name, options[:remote]).each do |version|
          graph.artifacts(plugin_name, version)
        end

        solution = Solve.it!(graph, [[plugin_name, constraint]])
        version  = solution[plugin_name]
        # don't search the remote for the plugin again; we would have already done that by
        # calling versions() and including a {remote: true} option.
        find(plugin_name, version, remote: false)
      end
    rescue Solve::Errors::NoSolutionError
      abort PluginNotFound.new(plugin_name, constraint)
    end

    # Uninstall an installed plugin
    #
    # @param [String] name
    #   Name of the plugin
    # @param [#to_s] version
    #   The version of the plugin to uninstall
    #
    # @return [MB::Plugin, nil]
    def uninstall(name, version)
      unless plugin = find(name, version, remote: false)
        return nil
      end

      FileUtils.rm_rf(install_path_for(plugin))
      remove(plugin)

      plugin
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
      all_versions = installed_versions(name)

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
      remote_cookbook_versions(name).collect do |version|
        (plugin = load_remote(name, version)).nil? ? nil : plugin.version.to_s
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

    private

      def finalize_callback
        log.debug { "Plugin Manager stopping..." }
      end

      # Load a plugin from a file
      #
      # @param [#to_s] path
      #   path to the file to load
      #
      # @option options [Boolean] :force (true)
      #   load a plugin even if a plugin of the same name and version is already loaded
      #
      # @raise [PluginSyntaxError] if there was a syntax error in the plugin loaded
      # @raise [PluginLoadError]
      #
      # @return [MB::Plugin]
      #   the loaded plugin
      def load_file(path, options = {})
        options = options.reverse_merge(force: true)
        plugin  = Plugin.from_path(path.to_s)

        add(plugin, options)
        plugin
      end

      # @return [Array<Pathname>]
      def installed_cookbooks
        Berkshelf.cookbooks(with_plugin: true)
      end

      # List all the versions of the given cookbook on the remote Chef server
      #
      # @param [String] name
      #   name of the cookbook to retrieve versions of
      #
      # @return [Array<String>]
      def remote_cookbook_versions(name)
        chef_connection.cookbook.versions(name)
      rescue Ridley::Errors::ResourceNotFound
        []
      end

      # List all of the cookbooks and their versions present on the remote
      #
      # @example return value
      #   {
      #     "ant" => [
      #       "0.10.1"
      #     ],
      #     "apache2" => [
      #       "1.4.0"
      #     ]
      #   }
      #
      # @return [Hash]
      #   a hash containing keys which represent cookbook names and values which contain
      #   an array of strings representing the available versions
      def remote_cookbooks
        chef_connection.cookbook.all
      end
  end
end
