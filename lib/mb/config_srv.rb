module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ConfigSrv
    include Celluloid
    include Celluloid::Notifications

    UPDATE_MSG = 'config_srv.configure'.freeze

    attr_reader :config

    def initialize(new_config)
      update(new_config)
    end

    def update(new_config)
      new_config.validate!
      @config = new_config
      publish(UPDATE_MSG)
    end
  end
end
