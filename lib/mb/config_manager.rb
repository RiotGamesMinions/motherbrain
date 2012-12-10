module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ConfigManager
    include Celluloid
    include Celluloid::Notifications

    UPDATE_MSG = 'config_manager.configure'.freeze

    # @return [MB::Config]
    attr_reader :config

    # @param [MB::Config] new_config
    def initialize(new_config)
      set_config(new_config)
    end

    # Update the current configuration
    #
    # @param [MB::Config] new_config
    def update(new_config)
      set_config(new_config)

      MB.log.debug "[ConfigManager] Configuration has changed: notifying subscribers..."
      publish(UPDATE_MSG, self.config)
    end

    private

      # @param [MB::Config] new_config
      def set_config(new_config)
        new_config.validate!
        @config = new_config
      end
  end
end
