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
        provisioner_klass = unless options[:with].nil?
          Provisioners.get(options[:with])
        else
          Provisioners.default
        end

        provisioner = provisioner_klass.new_link(options)
        provisioner.future(:run, environment, manifest)
      end
    end
  end
end
