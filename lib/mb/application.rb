trap 'INT' do
  MB.log.info "Shutting down..."
  MB::Application.instance.interrupt
end

trap 'TERM' do
  MB.log.info "Shutting down..."
  MB::Application.instance.interrupt
end

trap 'HUP' do
  MB.log.info "Reloading configuration..."
  MB::ConfigManager.instance.reload
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

      # The Actor registry for MotherBrain.
      #
      # @note MotherBrain uses it's own registry instead of Celluloid::Registry.root to
      #   avoid conflicts in the larger namespace. Use MB::Application[] to access MotherBrain
      #   actors instead of Celluloid::Actor[].
      #
      # @return [Celluloid::Registry]
      attr_reader :registry

      def_delegator :bootstrap_manager, :bootstrap
      def_delegator :provisioner_manager, :provision
      def_delegator :upgrade_manager, :upgrade
      def_delegator "MB::ConfigManager.instance", :config

      def_delegators :registry, :[], :[]=

      # @raise [Celluloid::DeadActorError] if Application has not been started
      #
      # @return [Celluloid::SupervisionGroup(Application)]
      def instance
        MB::Application[:motherbrain] or raise Celluloid::DeadActorError, "application not running"
      end

      # Run the application asynchronously (terminate after execution)
      #
      # @param [MB::Config] app_config
      def run!(app_config)
        MB::FileSystem.init
        MB::Application[:motherbrain] = group = super()

        # Config and I/O
        group.supervise_as :config_manager, ConfigManager, app_config
        group.supervise_as :ridley, Ridley::Client, config.to_ridley

        # Abstraction around the above
        group.supervise_as :node_querier, NodeQuerier

        # Services required for orchestration
        group.supervise_as :job_manager, JobManager
        group.supervise_as :lock_manager, Locks::Manager
        group.supervise_as :plugin_manager, PluginManager

        # Userland workers
        group.supervise_as :bootstrap_manager, Bootstrap::Manager
        group.supervise_as :provisioner_manager, Provisioner::Manager
        group.supervise_as :upgrade_manager, Upgrade::Manager

        if config.rest_gateway.enable
          group.supervise_as :rest_gateway, RestGateway, config.to_rest_gateway
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
        Bootstrap::Manager.instance
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @raise [Celluloid::DeadActorError] if job manager has not been started
      #
      # @return [Celluloid::Actor(JobManager)]
      def job_manager
        JobManager.instance
      end

      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(NodeQuerier)]
      def node_querier
        NodeQuerier.instance
      end

      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(PluginManager)]
      def plugin_manager
        PluginManager.instance
      end

      # @raise [Celluloid::DeadActorError] if Provisioner Manager has not been started
      #
      # @return [Celluloid::Actor(Provisioner::Manager)]
      def provisioner_manager
        Provisioner::Manager.instance
      end
      alias_method :provisioner, :provisioner_manager

      # @raise [Celluloid::DeadActorError] if Ridley has not been started
      #
      # @return [Celluloid::Actor(Ridley::Connection)]
      def ridley
        MB::Application[:ridley] or raise Celluloid::DeadActorError, "Ridley not running"
      end
      alias_method :chef_connection, :ridley

      # @raise [Celluloid::DeadActorError] if Upgrade Manager has not been started
      #
      # @return [Celluloid::Actor(Ridley::Connection)]
      def upgrade_manager
        MB::Application[:upgrade_manager] or raise Celluloid::DeadActorError, "upgrade manager not running"
      end
    end

    @registry = Celluloid::Registry.new

    include Celluloid::Notifications
    include MB::Logging

    def initialize(*args)
      super(self.class.registry)
      log.info { "MotherBrain starting..." }
      @interrupt_mutex = Mutex.new
      @interrupted     = false
      subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
    end

    def reconfigure(_msg, new_config)
      log.debug { "[Application] ConfigManager has changed: re-configuring components..." }
      self.class.ridley.async.configure(new_config.to_ridley)
    end

    def interrupt
      interrupt_mutex.synchronize do
        unless interrupted
          @interrupted = true

          reverse_terminate
        end
      end
    end

    # Terminate our child processes in reverse order
    #
    # @see https://github.com/celluloid/celluloid/pull/152
    def reverse_terminate
      @members.reverse_each(&:terminate)

      terminate
    end

    def finalize
      log.info { "MotherBrain stopping..." }
    end

    private

      attr_reader :interrupt_mutex
      attr_reader :interrupted
  end
end
