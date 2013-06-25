module MotherBrain
  module ApiHelpers
    include MB::Mixin::Services

    # @param [String] name
    # @param [String] version (nil)
    #
    # @return [Plugin]
    def find_plugin!(name, version = nil)
      version = convert_uri_version(version)

      unless plugin = plugin_manager.find(name, version)
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

    def convert_uri_version(version)
      return nil if version.nil?

      ver_string = version.gsub('_', '.')
      Solve::Version.split(ver_string)
      ver_string
    end
  end
end
