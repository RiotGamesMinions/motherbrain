module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ConfigManager
    class << self
      # @raise [Celluloid::DeadActorError] if ConfigManager has not been started
      #
      # @return [Celluloid::Actor(ConfigManager)]
      def instance
        Celluloid::Actor[:config_manager] or raise Celluloid::DeadActorError, "config manager not running"
      end
    end

    include Celluloid
    include Celluloid::Notifications

    UPDATE_MSG = 'config_manager.configure'.freeze

    # @return [MB::Config]
    attr_reader :config

    # @param [MB::Config] new_config
    def initialize(new_config)
      @reload_mutex = Mutex.new
      @reloading    = false
      set_config(new_config)
    end

    # Update the current configuration
    #
    # @param [MB::Config] new_config
    def update(new_config)
      set_config(new_config)

      MB.log.info "[ConfigManager] Configuration has changed: notifying subscribers..."
      publish(UPDATE_MSG, self.config)
    end

    # Reload the current configuration from disk
    def reload
      reload_mutex.synchronize do
        unless reloading?
          @reloading = true
          update(config.reload)
        end
      end

      @reloading = false
    end

    # Check if the config manager is already attempting to reload it's configuration
    #
    # @return [Boolean]
    def reloading?
      @reloading
    end

    private

      # @return [Mutex]
      attr_reader :reload_mutex

      # @param [MB::Config] new_config
      def set_config(new_config)
        new_config.validate!
        @config = new_config
      end
  end
end
