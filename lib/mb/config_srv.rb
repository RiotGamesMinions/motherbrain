module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ConfigSrv
    include Celluloid

    attr_reader :config

    def initialize(app_config)
      Config.validate!(app_config)

      @config = app_config
    end
  end
end
