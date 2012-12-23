module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class PluginManager
    class << self
      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(PluginManager)]
      def instance
        Celluloid::Actor[:plugin_manager] or raise Celluloid::DeadActorError, "plugin manager not running"
      end

      # Returns a Set of expanded file paths that are directories that may contain
      # MotherBrain plugins.
      #
      # If the MB_PLUGIN_PATH environment variable is set the value of the variable
      # will be used as the default plugin path.
      #
      # @return [Set<String>]
      def default_paths
        if ENV["MB_PLUGIN_PATH"].nil?
          defaults = [
            FileSystem.plugins.to_s,
            File.expand_path(File.join(".", ".mb", "plugins"))
          ]

          Set.new(defaults)
        else
          Set.new.add(File.expand_path(ENV["MB_PLUGIN_PATH"]))
        end
      end
    end

    include Celluloid
    include MB::Logging

    # @return [Set<Pathname>]
    attr_reader :paths

    # @return [Set<Plugin>]
    attr_reader :plugins

    def initialize
      log.info { "Plugin Manager starting..." }
      @paths   = Set.new
      @plugins = Set.new

      Application.config.plugin_paths.each { |path| self.add_path(path) }
      load_all
    end

    # @param [MotherBrain::Plugin] plugin
    #
    # @raise [AlreadyLoaded] if a plugin of the same name and version has already been loaded
    def add(plugin)
      unless find(plugin.name, plugin.version).nil?
        raise AlreadyLoaded, "A plugin with the name: '#{plugin.name}' and version: '#{plugin.version}' is already loaded"
      end

      @plugins.add(plugin)
    end

    # @param [String, Pathname] path
    def add_path(path)
      self.paths.add(Pathname.new(File.expand_path(path)))
    end

    # Clear all previously set paths
    #
    # @note this is for testing; you probably don't want to use this
    #
    # @return [Set]
    def clear_paths
      @paths = Set.new
    end

    # Clear list of known plugins
    #
    # @note this is for testing; you probably don't want to use this
    #
    # @return [Set]
    def clear_plugins
      @plugins = Set.new
    end

    # @param [String] name
    # @param [#to_s] version
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
      self.paths.each do |path|
        Pathname.glob(path.join('*.rb')).collect do |plugin|
          self.load(plugin)
        end
      end

      self.plugins
    end

    # @param [#to_s] path
    #
    # @raise [AlreadyLoaded] if a plugin of the same name and version has already been loaded
    def load(path)
      add Plugin.from_file(path.to_s)
    end

    # @param [Pathname] path
    def remove_path(path)
      self.paths.delete(path)
    end

    def finalize
      log.info { "Plugin Manager stopping..." }
    end
  end
end
