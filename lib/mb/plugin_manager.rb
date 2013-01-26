module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
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

    # @return [Pathname]
    attr_reader :berkshelf_path
    
    # Tracks when the plugin manager will attempt to load remote plugins from the Chef Server. If
    # remote loading is disabled this will return nil.
    #
    # @return [Timers::Timer, nil]
    attr_reader :eager_load_timer

    def initialize
      log.info { "Plugin Manager starting..." }
      @berkshelf_path = MB::Berkshelf.path
      @plugins        = Set.new

      MB::Berkshelf.init
      load_all

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

    def finalize
      log.info { "Plugin Manager stopping..." }
    end

    # Find and return a registered plugin of the given name and version. If no version
    # attribute is specified the latest version of the plugin is returned.
    #
    # @param [String] name
    # @param [#to_s] version (nil)
    #
    # @return [Plugin, nil]
    def find(name, version = nil)
      plugins.sort.reverse.find do |plugin|
        if version.nil?
          plugin.name == name
        else
          plugin.name == name && plugin.version.to_s == version.to_s
        end
      end
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
    # @return [Set<MB::Plugin>, nil]
    def load_file(path, options = {})
      options = options.reverse_merge(force: true)

      add(Plugin.from_path(path.to_s), options)
    end

    # Load a plugin from a cookbook resource
    #
    # @param [Ridley::CookbookResource] resource
    #
    # @option options [Boolean] :force (false)
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @return [Set<MB::Plugin>, nil]
    def load_resource(resource, options = {})
      options = options.reverse_merge(force: false)

      unless resource.has_motherbrain_plugin?
        return nil
      end

      begin
        scratch_dir   = FileSystem.tmpdir("cbplugin")
        metadata_path = File.join(scratch_dir, Plugin::METADATA_FILENAME)
        plugin_path   = File.join(scratch_dir, Plugin::PLUGIN_FILENAME)

        unless resource.download_file(:root_file, Plugin::PLUGIN_FILENAME, metadata_path) &&
          resource.download_file(:root_file, Plugin::METADATA_FILENAME, plugin_path)

          raise PluginDownloadError, "failure downloading plugin files for #{resource}"
        end

        load_file(scratch_dir, options)
      ensure
        FileUtils.rm_rf(scratch_dir)
      end
    end

    # A set of all the registered plugins
    #
    # @param [String, nil] name (nil)
    #   an optional parameter which if provided will filter the results to include only
    #   plugins which match the given name
    #
    # @return [Set<Plugin>]
    def plugins(name = nil)
      if name.nil?
        @plugins
      else
        @plugins.select { |plugin| plugin.name == name }
      end
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

      # Load all of the plugins from the Berkshelf
      #
      # @param [Boolean] force (false)
      def load_all_local(force = false)
        Berkshelf.cookbooks(with_plugin: true).each do |path|
          load_file(path, force: force)
        end
      rescue PluginSyntaxError, PluginLoadError => ex
        log.warn { "error loading local plugin: #{ex}" }
      end

      # Load all of the plugins from the remote Chef Server
      def load_all_remote
        Application.ridley.cookbook.all.collect do |name, versions|
          versions.each do |version|
            load_resource(Application.ridley.cookbook.find(name, version))
          end
        end
      rescue PluginSyntaxError, PluginLoadError, PluginDownloadError => ex
        log.warn { "error loading remote plugin: #{ex}" }
      end
  end
end
