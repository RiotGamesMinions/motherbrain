module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  #
  # Main Application supervisor for MotherBrain.
  #
  class Application < Celluloid::SupervisionGroup
    class << self
      extend Forwardable

      def_delegator :provisioner_manager, :provision
      def_delegator :bootstrap_manager, :bootstrap

      # @return [Celluloid::Actor]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager]
      end
      alias_method :provisioner, :provisioner_manager

      # @return [Celluloid::Actor]
      def bootstrap_manager
        Celluloid::Actor[:bootstrap_manager]
      end
      alias_method :bootstrapper, :bootstrap_manager
    end

    supervise Provisioner::Manager, as: :provisioner_manager
    supervise Bootstrap::Manager, as: :bootstrap_manager
  end
end
