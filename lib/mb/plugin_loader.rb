module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class PluginLoader
    class << self
      def default_paths
        Set.new [
          File.expand_path(File.join("~/", ".mb", "plugins")),
          File.expand_path(File.join(".", ".mb", "plugins"))
        ]
      end
    end

    # @return [MB::Context]
    attr_reader :context

    # @param [MotherBrain::Context] context
    def initialize(context)
      @context = context
      @plugins = Hash.new

      context.config.plugin_paths.each { |path| self.add_path(path) }
    end

    # @return [Array<MotherBrain::Plugin>]
    def plugins
      @plugins.values
    end

    # @param [String] name
    # @param [Version] version
    #
    # @return [MotherBrain::Plugin]
    def plugin(name, version)
      @plugins.fetch(Plugin.key_for(name, version), nil)
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
      add Plugin.from_file(self.context, path.to_s)
    end

    # @return [Set<Pathname>]
    def paths
      @paths ||= Set.new
    end

    # @param [String, Pathname] path
    def add_path(path)
      self.paths.add(Pathname.new(path))
    end

    # @param [Pathname] path
    def remove_path(path)
      self.paths.delete(path)
    end

    # Clear all previously set paths
    #
    # @return [Set]
    def clear_paths!
      @paths = Set.new
    end

    private

      # @param [MotherBrain::Plugin] plugin
      #
      # @raise [AlreadyLoaded] if a plugin of the same name and version has already been loaded
      def add(plugin)
        if @plugins.has_key?(plugin.id)
          raise AlreadyLoaded, "A plugin with the name: '#{plugin.name}' and version: '#{plugin.version}' is already loaded"
        end

        @plugins[plugin.id] = plugin
      end
  end
end
