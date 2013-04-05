module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module ApiHelpers
    include MB::Mixin::Services

    # @param [String] name
    # @param [String] version (nil)
    #
    # @return [Plugin]
    def find_plugin!(name, version = nil)
      plugin = if version.nil?
        plugin_manager.latest(name)
      else
        plugin_manager.find(name, version)
      end

      if plugin.nil?
        raise PluginNotFound.new(name, version)
      end

      plugin
    end

    # @param [String] id
    #
    # @return [JobRecord]
    def find_job!(id)
      job = job_manager.find(id)

      if job.nil?
        raise JobNotFound.new(id)
      end

      job
    end
  end
end
