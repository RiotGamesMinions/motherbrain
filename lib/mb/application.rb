module MotherBrain
  class Application < Celluloid::SupervisionGroup
    class << self
      # @return [Celluloid::Actor]
      def provisioner_manager
        Celluloid::Actor[:provisioner_manager]
      end
      alias_method :provisioner, :provisioner_manager
    end

    supervise Provisioner::Manager, as: :provisioner_manager
  end
end
