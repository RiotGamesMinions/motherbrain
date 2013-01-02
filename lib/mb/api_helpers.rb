module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module ApiHelpers
    def bootstrapper
      Bootstrap::Manager.instance
    end

    def plugin_manager
      PluginManager.instance
    end

    def provisioner
      Provisioner::Manager.instance
    end

    # @param [String] name (nil)
    #
    # @return [Array<Plugin>]
    def list_plugins!(name = nil)
      plugins = plugin_manager.plugins(name)

      if plugins.empty?
        raise PluginNotFound.new(name)
      end

      plugins
    end

    # @param [String] name
    # @param [String] version (nil)
    #
    # @return [Plugin]
    def find_plugin!(name, version = nil)
      plugin = plugin_manager.find(name, version)

      if plugin.nil?
        raise PluginNotFound.new(name, version)
      end

      plugin
    end

    # @param [String] id
    #
    # @return [JobRecord]
    def find_job!(id)
      job = JobManager.instance.find(id)

      if job.nil?
        raise JobNotFound.new(id)
      end

      job
    end
  end
end
