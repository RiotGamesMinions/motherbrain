module MotherBrain
  class AppSupervisor < Celluloid::SupervisionGroup
    supervise Provisioner::Manager, as: :provisioner_manager
  end
end
