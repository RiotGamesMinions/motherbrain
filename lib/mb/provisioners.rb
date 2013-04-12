module MotherBrain
  # @author Jamie Winsor <reset@riotgames.com>
  module Provisioners
    DEFAULT_PROVISIONER_ID = :environment_factory

    class << self
      attr_reader :default_id

      # @param [Class] klass
      # @option options [Boolean] :default
      #
      # @raise [ProvisionerRegistrationError] if a provisioner is registered as the default provisioner when
      #   a default provisioner already exists
      #
      # @return [Set]
      def register(klass, options = {})
        validate_provisioner_class(klass)

        unless get(klass.provisioner_id).nil?
          raise ProvisionerRegistrationError, "A provisioner with the id '#{klass.provisioner_id}' has already been registered"
        end

        if options[:default]
          unless @default_id.nil?
            raise ProvisionerRegistrationError, "A default provisioner has already been defined (#{default_id})"
          end

          @default_id = klass.provisioner_id
        end

        all.add(klass)
      end

      # List of all the registered provisioners
      #
      # @return [Set]
      def all
        @all ||= Set.new
      end

      # Get registered provisioner class from the given ID. Return nil if no provisioner with
      # the corresponding ID is found
      #
      # @param [#to_sym] id
      #
      # @return [Class, nil]
      def get(id)
        all.find { |klass| klass.provisioner_id == id.to_sym }
      end

      # Get registered provisioner class fromt he given ID. Raise an error if no provisioner with
      # the corresponding ID is found
      #
      # @raise [ProvisionerNotRegistered] if no provisioner with the corresponding ID is found
      #
      # @return [Class]
      def get!(id)
        provisioner = get(id)

        if provisioner.nil?
          raise ProvisionerNotRegistered, "No provisioner registered with the ID: '#{id}'"
        end

        provisioner
      end

      # Return the default provisioner if one has been registered as the default
      #
      # @return [Class, nil]
      def default
        # TODO: make this better
        _default_id = ENV['MB_DEFAULT_PROVISIONER'] || self.default_id
        _default_id ? get(_default_id) : nil
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
