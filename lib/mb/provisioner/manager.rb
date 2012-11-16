module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Manager
      include Celluloid

      # @param [String] environment
      # @param [Hash] manifest
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Celluloid::Future]
      def provision(environment, manifest, options = {})
        provisioner_klass = choose_provisioner(options[:with])

        provisioner = provisioner_klass.new_link(options)
        provisioner.future(:up, environment, manifest)
      end

      # @param [String] environment
      # @option options [#to_sym] :with
      #   id of provisioner to use
      #
      # @return [Celluloid::Future]
      def destroy(environment, options = {})
        provisioner_klass = choose_provisioner(options[:with])

        provisioner = provisioner_klass.new_link(options)
        provisioner.future(:down, environment)
      end

      protected

        def choose_provisioner(id)
          id.nil? ? Provisioners.default : Provisioners.get(id)
        end
    end
  end
end
