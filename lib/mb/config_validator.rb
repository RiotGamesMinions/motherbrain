module MotherBrain
  class ConfigValidator < ActiveModel::Validator
    def validate(record)
      if record.ssh_password.blank? && record.ssh_key.blank?
        record.errors.add(:ssh_password, "You must specify an SSH password or an SSH key")
        record.errors.add(:ssh_key, "You must specify an SSH password or an SSH key")
      end
    end
  end
end
