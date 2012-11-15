module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    DEFAULT_PROVISIONER_ID = :environment_factory
    
    class << self
      def register(klass)
        validate_provisioner_class(klass)

        all.add(klass)
      end

      def default
        get(DEFAULT_PROVISIONER_ID)
      end

      # @return [Set]
      def all
        @all ||= Set.new
      end

      # Clears all of the registered Provisioners.
      #
      # @return [Set]
      #   an empty Set
      def clear!
        @all = Set.new
      end

      # @param [Symbol] klass
      #
      # @raise [InvalidProvisionerClass] if the class does not respond to provisioner_id
      #
      # @return [Boolean]
      def validate_provisioner_class(klass)
        unless klass.respond_to?(:provisioner_id)
          raise InvalidProvisionerClass, "Cannot register provisioner: all provisioners must respond to ':provisioner_id'"
        end

        if klass.provisioner_id.nil?
          raise InvalidProvisionerClass, "Cannot register provisioner: invalid provisioner_id '#{klass.provisioner_id}'"
        end

        true
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/provisioners/*.rb"].sort.each do |path|
  require "mb/provisioners/#{File.basename(path, '.rb')}"
end
