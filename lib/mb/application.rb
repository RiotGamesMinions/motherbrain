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
        group.supervise_as :lock_manager, Locks::Manager
        group.supervise_as :ridley, Ridley::Connection, config.to_ridley

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
        Celluloid::Actor[:config_srv] or raise Celluloid::DeadActorError, "config srv not running"
      end

      # @return [Celluloid::Actor(Provisioner::Manager)]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager] or raise Celluloid::DeadActorError, "provisioner manager not running"
      end
      alias_method :provisioner, :provisioner_manager

      # @return [Celluloid::Actor(Bootstrap::Manager)]
      def bootstrap_manager
        Celluloid::Actor[:bootstrap_manager] or raise Celluloid::DeadActorError, "bootstrap manager not running"
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @return [Celluloid::Actor(NodeQuerier)]
      def node_querier
        Celluloid::Actor[:node_querier] or raise Celluloid::DeadActorError, "node querier not running"
      end

      def ridley
        Celluloid::Actor[:ridley] or raise Celluloid::DeadActorError, "Ridley not running"
      end
      alias_method :chef_connection, :ridley
    end

    include Celluloid::Notifications

    def initialize(*args)
      super
      subscribe(ConfigSrv::UPDATE_MSG, :reconfigure)
    end

    def reconfigure(_msg, new_config)
      MB.log.debug "[Application] ConfigSrv has changed: re-configuring components..."
      self.class.ridley.configure(new_config.to_ridley)
    end
  end
end
