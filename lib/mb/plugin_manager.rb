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
      Berkshelf.cookbooks(with_plugin: true).each do |path|
        self.load(path)
      end

      self.plugins
    end

    # @param [#to_s] path
    #
    # @option options [Boolean] :force
    #   load a plugin even if a plugin of the same name and version is already loaded
    #
    # @raise [AlreadyLoaded]
    #   if a plugin of the same name and version has already been loaded. This can be overridden
    #   by providing 'true' for the :force option.
    def load(path, options = {})
      add(Plugin.from_path(path.to_s), options)
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
          log.debug { "[Plugin Manager] Berkshelf location has changed; reloading plugins" }

          @berkshelf_path = Berkshelf.path
          reload_all
        end
      end
  end
end
