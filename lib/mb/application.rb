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

      # Run the application asynchronously (terminate after execution)
      #
      # @param [MB::Config] config
      def run!(config)
        group = super()
        group.configure(config)
        group.supervise_as(:node_querier, NodeQuerier, group.chef_conn)

        group
      end

      # Run the application in the foreground (sleep on main thread)
      #
      # @param [MB::Config] config
      def run(config)
        loop do
          supervisor = run!(config)

          sleep 5 while supervisor.alive?

          Logger.error "!!! Celluloid::SupervisionGroup #{self} crashed. Restarting..."
        end
      end

      # @param [MB::Config] config
      #
      # @raise [MB::InvalidConfig] if the given configuration is invalid
      def validate_config!(config)
        unless config.valid?
          raise InvalidConfig.new(config.errors)
        end
      end

      # @return [Celluloid::Actor(Provisioner::Manager)]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager]
      end
      alias_method :provisioner, :provisioner_manager

      # @return [Celluloid::Actor(Bootstrap::Manager)]
      def bootstrap_manager
        Celluloid::Actor[:bootstrap_manager]
      end
      alias_method :bootstrapper, :bootstrap_manager

      # @return [Celluloid::Actor(NodeQuerier)]
      def node_querier
        Celluloid::Actor[:node_querier]
      end
    end

    supervise Provisioner::Manager, as: :provisioner_manager
    supervise Bootstrap::Manager, as: :bootstrap_manager

    # @return [MB::Config]
    attr_reader :config

    # @return [Ridley::Connection]
    attr_reader :chef_conn

    # Configure the Application with the given MB::Config or leave nil and a default
    # configuration will be used
    #
    # @param [MB::Config] config
    #
    # @raise [MB::InvalidConfig] if the given configuration is invalid
    def configure(config)
      self.class.validate_config!(config)

      @config    = config
      @chef_conn = Ridley.connection(@config.to_ridley)
    end
  end
end
