trap 'INT' do
  MB.application.interrupt
end

trap 'TERM' do
  MB.application.interrupt
end

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
      def_delegator "MB::Config.manager", :config

      # Run the application asynchronously (terminate after execution)
      #
      # @param [MB::Config] app_config
      def run!(app_config)
        Celluloid::Actor[:motherbrain] = group = super()

        group.supervise_as :config_manager, ConfigManager, app_config
        group.supervise_as :plugin_manager, PluginManager
        group.supervise_as :provisioner_manager, Provisioner::Manager
        group.supervise_as :bootstrap_manager, Bootstrap::Manager
        group.supervise_as :node_querier, NodeQuerier
        group.supervise_as :lock_manager, Locks::Manager
        group.supervise_as :ridley, Ridley::Connection, config.to_ridley

        if config.rest_gateway.enable
          group.supervise_as :rest_gateway, REST::Gateway, config.to_rest_gateway
        end

        group
      end

      # Run the application in the foreground (sleep on main thread)
      #
      # @param [MB::Config] app_config
      def run(app_config)
        loop do
          supervisor = run!(app_config)

          sleep 0.1 while supervisor.alive?

          Logger.error "!!! Celluloid::SupervisionGroup #{self} crashed. Restarting..."
        end
      end

      # @raise [Celluloid::DeadActorError] if Bootstrap Manager has not been started
      #
      # @return [Celluloid::Actor(Bootstrap::Manager)]
      def bootstrap_manager
        Celluloid::Actor[:bootstrap_manager] or raise Celluloid::DeadActorError, "bootstrap manager not running"
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(NodeQuerier)]
      def node_querier
        Celluloid::Actor[:node_querier] or raise Celluloid::DeadActorError, "node querier not running"
      end

      def plugin_manager
        Celluloid::Actor[:plugin_manager] or raise Celluloid::DeadActorError, "plugin manager not running"
      end

      # @raise [Celluloid::DeadActorError] if Provisioner Manager has not been started
      #
      # @return [Celluloid::Actor(Provisioner::Manager)]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager] or raise Celluloid::DeadActorError, "provisioner manager not running"
      end
      alias_method :provisioner, :provisioner_manager

      # @raise [Celluloid::DeadActorError] if Ridley has not been started
      #
      # @return [Celluloid::Actor(Ridley::Connection)]
      def ridley
        Celluloid::Actor[:ridley] or raise Celluloid::DeadActorError, "Ridley not running"
      end
      alias_method :chef_connection, :ridley
    end

    include Celluloid::Notifications

    def initialize(*args)
      super
      @interrupt_mutex = Mutex.new
      @interrupted     = false
      subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
    end

    def reconfigure(_msg, new_config)
      MB.log.debug "[Application] ConfigManager has changed: re-configuring components..."
      self.class.ridley.async.configure(new_config.to_ridley)
    end

    def interrupt
      interrupt_mutex.synchronize do
        unless interrupted
          interrupted = true
          Thread.main.raise Interrupt
        end
      end
    end

    private

      attr_reader :interrupt_mutex
      attr_reader :interrupted
  end
end
