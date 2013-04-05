module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module ApiHelpers
    include MB::Mixin::Services

    # @param [String] name
    # @param [String] version (nil)
    #
    # @return [Plugin]
    def find_plugin!(name, version = nil)
      plugin = if version
        plugin_manager.find(name, version)
      else
        plugin_manager.latest(name)
      end

      unless plugin
        raise PluginNotFound.new(name, version)
      end

      plugin
    end

    # @param [String] id
    #
    # @return [JobRecord]
    def find_job!(id)
      job = job_manager.find(id)

      unless job
        raise JobNotFound.new(id)
      end

      job
    end
  end
end
