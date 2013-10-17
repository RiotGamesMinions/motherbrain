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
end if Signal.supported?('HUP')

module MotherBrain
  # Main application supervisor for motherbrain
  #
  # @example running the application in the foreground
  #   MB::Application.run(config)
  #
  # @example running the application in the background
  #   MB::Application.run!(config)
  module Application
    class << self
      extend Forwardable
      include MB::Mixin::Services
      include MB::Logging

      def_delegator :upgrade_manager, :upgrade
      def_delegator :config_manager, :config

      def_delegators :registry, :[], :[]=

      # @raise [Celluloid::DeadActorError] if Application has not been started
      #
      # @return [Celluloid::SupervisionGroup(MB::Application::SupervisionGroup)]
      def instance
        return @instance unless @instance.nil?

        raise Celluloid::DeadActorError, "application not running"
      end

      # The Actor registry for motherbrain.
      #
      # @note motherbrain uses it's own registry instead of Celluloid::Registry.root to
      #   avoid conflicts in the larger namespace. Use MB::Application[] to access motherbrain
      #   actors instead of Celluloid::Actor[].
      #
      # @return [Celluloid::Registry]
      def registry
        @registry ||= Celluloid::Registry.new
      end

      # Run the application asynchronously (terminate after execution)
      #
      # @param [MB::Config] config
      def run!(config)
        Celluloid.boot
        log.info { "motherbrain starting..." }
        setup
        @instance = Application::SupervisionGroup.new(config)
      end

      # Run the application in the foreground (sleep on main thread)
      #
      # @param [MB::Config] config
      def run(config)
        loop do
          supervisor = run!(config)

          sleep 0.1 while supervisor.alive?

          break if supervisor.interrupted

          log.fatal { "!!! #{self} crashed. Restarting..." }
        end
      end

      # Prepare the application and environment to run motherbrain
      def setup
        MB::Test.mock(:setup) if MB.testing?
        MB::FileSystem.init
      end

      # Stop the running application
      def stop
        instance.terminate
      end
    end

    class SupervisionGroup < ::Celluloid::SupervisionGroup
      include Celluloid::Notifications
      include MB::Logging

      attr_reader :interrupted

      def initialize(config)
        super(MB::Application.registry)

        supervise_as(:config_manager, MB::ConfigManager, config)
        supervise_as(:ridley, Ridley::Client, config.to_ridley)
        supervise_as(:job_manager, MB::JobManager)
        supervise_as(:lock_manager, MB::LockManager)
        supervise_as(:plugin_manager, MB::PluginManager)
        supervise_as(:command_invoker, MB::CommandInvoker)
        supervise_as(:node_querier, MB::NodeQuerier)
        supervise_as(:environment_manager, MB::EnvironmentManager)
        supervise_as(:bootstrap_manager, MB::Bootstrap::Manager)
        supervise_as(:provisioner_manager, MB::Provisioner::Manager)
        supervise_as(:upgrade_manager, MB::Upgrade::Manager)

        if config.rest_gateway.enable
          supervise_as(:rest_gateway, MB::RestGateway, config.to_rest_gateway)
        end

        @interrupt_mutex = Mutex.new
        @interrupted     = false
        subscribe(ConfigManager::UPDATE_MSG, :reconfigure)
        MB::Test.mock(:init) if MB.testing?
      end

      def reconfigure(_msg, new_config)
        log.debug { "[Application] ConfigManager has changed: re-configuring components..." }
        @registry[:ridley].async.configure(new_config.to_ridley)
      end

      def interrupt
        interrupt_mutex.synchronize do
          unless interrupted
            @interrupted = true

            terminate
          end
        end
      end

      private

        attr_reader :interrupt_mutex
    end
  end
end
