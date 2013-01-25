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

    POLL_INTERVAL = 300

    include Celluloid
    include Celluloid::Notifications
    include MB::Logging

    # @return [Pathname]
    attr_reader :berkshelf_path

    def initialize
      log.info { "Plugin Manager starting..." }
      @berkshelf_path = MB::Berkshelf.path
      @plugins        = Set.new

      load_all

      subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
    end

    # Add a plugin to the set of plugins
    #
    # @param [MotherBrain::Plugin] plugin
    #
    # @option options [Boolean] :force
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @raise [AlreadyLoaded]
    #   if a plugin of the same name and version has already been loaded. This can be overridden
    #   by providing 'true' for the :force option.
    def add(plugin, options = {})
      if options[:force]
        return reload(plugin)
      end

      unless find(plugin.name, plugin.version).nil?
        raise AlreadyLoaded, "A plugin with the name: '#{plugin.name}' and version: '#{plugin.version}' is already loaded"
      end

      @plugins.add(plugin)
    end

    # Clear list of known plugins
    #
    # @return [Set]
    def clear_plugins
      @plugins.clear
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

    # @raise [AlreadyLoaded] if a plugin of the same name and version has already been loaded
    #
    # @return [Array<MotherBrain::Plugin>]
    def load_all
      load_all_local
    end

    # Load a plugin from a file
    #
    # @param [#to_s] path
    #
    # @option options [Boolean] :force (true)
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @raise [AlreadyLoaded]
    #   if a plugin of the same name and version has already been loaded. This can be overridden
    #   by providing 'true' for the :force option.
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
    # @raise [AlreadyLoaded]
    #   if a plugin of the same name and version has already been loaded. This can be overridden
    #   by providing 'true' for the :force option.
    def load_resource(resource, options = {})
      options = options.reverse_merge(force: false)

      unless resource.has_motherbrain_plugin?
        return nil
      end

      begin
        scratch_dir   = FileSystem.tmpdir("cbplugin")
        metadata_path = File.join(scratch_dir, Plugin::METADATA_FILENAME)
        plugin_path   = File.join(scratch_dir, Plugin::PLUGIN_FILENAME)

        cookbook_resource.download_file(:root_file, Plugin::PLUGIN_FILENAME, metadata_path)
        cookbook_resource.download_file(:root_file, Plugin::METADATA_FILENAME, plugin_path)

        load_file(scratch_dir, options)
      ensure
        FileUtils.rm_rf(scratch_dir)
      end
    end

    # Return all of the registered plugins. If the optional name parameter is provided the
    # results will be filtered and only plugin versions of that given name will be returned
    #
    # @param [String, nil] name (nil)
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

    # Reload plugins from the Berkshelf
    #
    # @return [Array<MotherBrain::Plugin>]
    def reload_all
      clear_plugins
      load_all
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
          reload_all
        end
      end

      def load_all_local
        Berkshelf.cookbooks(with_plugin: true).each do |path|
          load_file(path)
        end
      end

      def load_all_remote
        Application.ridley.cookbook.all.collect do |name, versions|
          versions.each do |version|
            load_resource(Application.ridley.cookbook.find(name, version))
          end
        end
      end
  end
end
