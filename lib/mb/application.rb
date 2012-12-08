module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Main application supervisor for MotherBrain
  #
  # @example running the application in the foreground
  #   MB::Application.run(config)
  #
  # @example running the application asynchronously
  #   MB::Application.run!(config)
  #   
  class Application < Celluloid::SupervisionGroup
    class << self
      extend Forwardable

      def_delegator :provisioner_manager, :provision
      def_delegator :bootstrap_manager, :bootstrap

      # Return the configuration for the running application
      #
      # @return [MB::Config]
      def_delegator :config_srv, :config

      # Run the application asynchronously (terminate after execution)
      #
      # @param [MB::Config] app_config
      def run!(app_config)
        group = super()

        group.supervise_as :config_srv, ConfigSrv, app_config
        group.supervise_as :provisioner_manager, Provisioner::Manager
        group.supervise_as :bootstrap_manager, Bootstrap::Manager
        group.supervise_as :node_querier, NodeQuerier

        group
      end

      # Run the application in the foreground (sleep on main thread)
      #
      # @param [MB::Config] app_config
      def run(app_config)
        loop do
          supervisor = run!(app_config)

          sleep 5 while supervisor.alive?

          Logger.error "!!! Celluloid::SupervisionGroup #{self} crashed. Restarting..."
        end
      end

      # @return [Celluloid::Actor(ConfigSrv)]
      def config_srv
        Celluloid::Actor[:config_srv] or raise DeadActorError, "config srv not running"
      end

      # @return [Celluloid::Actor(Provisioner::Manager)]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager] or raise DeadActorError, "provisioner manager not running"
      end
      alias_method :provisioner, :provisioner_manager

      # @return [Celluloid::Actor(Bootstrap::Manager)]
      def bootstrap_manager
        Celluloid::Actor[:bootstrap_manager] or raise DeadActorError, "bootstrap manager not running"
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @return [Celluloid::Actor(NodeQuerier)]
      def node_querier
        Celluloid::Actor[:node_querier] or raise DeadActorError, "node querier not running"
      end

      def chef_connection
        config.to_ridley
      end
    end
  end
end
