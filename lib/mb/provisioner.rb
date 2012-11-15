module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioner
    autoload :Manager, 'mb/provisioner/manager'
    autoload :Manifest, 'mb/provisioner/manifest'

    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      # The identifier for the Provisioner
      #
      # @return [Symbol]
      attr_reader :provisioner_id

      # @param [#to_sym] provisioner_id
      def register_provisioner(provisioner_id, options = {})
        @provisioner_id = provisioner_id
        Provisioners.register(self, options)
      end
    end
  end
end
