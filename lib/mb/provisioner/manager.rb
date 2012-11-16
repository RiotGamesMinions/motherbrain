module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      class << self
        # Returns a provisioner for the given ID. The default provisioner will be returned
        # if nil is provided
        #
        # @param [#to_sym, nil] id
        #
        # @raise [ProvisionerNotRegistered] if no provisioner is registered with the given ID
        #
        # @return [Class]
        def choose_provisioner(id)
          id.nil? ? Provisioners.default : Provisioners.get!(id)
        end
      end

      include Celluloid

      # @param [String] environment
      # @param [Hash] manifest
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Celluloid::Future]
      def provision(environment, manifest, options = {})
        provisioner_klass = self.class.choose_provisioner(options[:with])

        provisioner = provisioner_klass.new_link(options)
        provisioner.future(:up, environment, manifest)
      end

      # @param [String] environment
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Celluloid::Future]
      def destroy(environment, options = {})
        provisioner_klass = self.class.choose_provisioner(options[:with])

        provisioner = provisioner_klass.new_link(options)
        provisioner.future(:down, environment)
      end
    end
  end
end
