module MotherBrain
  module Mixin
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # A mixin to provide easy access to the various services (actors) running in the
    # motherbrain stack.
    module Services
      # @raise [Celluloid::DeadActorError] if Bootstrap Manager has not been started
      #
      # @return [Celluloid::Actor(Bootstrap::Manager)]
      def bootstrap_manager
        Bootstrap::Manager.instance
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @raise [Celluloid::DeadActorError] if Config Manager has not been started
      #
      # @return [Celluloid::Actor(ConfigManager)]
      def config_manager
        ConfigManager.instance
      end

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
      # @return [Celluloid::Actor(Upgrade::Manager)]
      def upgrade_manager
        Upgrade::Manager.instance
      end
    end
  end
end
