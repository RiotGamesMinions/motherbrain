module MotherBrain
  module Provisioner
    # Handles persisting provision data to a Chef server, for use later by
    # other provisioner actions on that environment.
    class ProvisionData
      include MB::Mixin::Services

      DATA_BAG = '_motherbrain_provision_data_'

      attr_reader :environment_name

      # @param [Symbol] environment_name
      def initialize(environment_name)
        @environment_name = environment_name
      end

      # Returns a hash of stored instance data
      #
      # @return [Hash]
      def instances
        attributes[:instances] ||= {}

        attributes[:instances]
      end

      # Returns an array of provisioner names for this environment
      #
      # @return [Array(Symbol)]
      def provisioners
        instances.keys
      end

      # Returns an array of instance hashes for a provisioner
      #
      # @param [Symbol] provisioner_name
      #
      # @return [Array(Hash)]
      def instances_for_provisioner(provisioner_name)
        instances[provisioner_name] ||= []

        instances[provisioner_name]
      end

      # Adds instances to the provision data idempotently
      #
      # @param [Symbol] provisioner_name
      # @param [Array(Hash)] instance_array
      def add_instances_to_provisioner(provisioner_name, instance_array)
        instance_array.each do |instance|
          unless instances_for_provisioner(provisioner_name).include?(instance)
            instances_for_provisioner(provisioner_name).push instance
          end
        end
      end

      # Removes an instance from the provisioner by matching a key/value pair
      #
      # @param [Symbol] provisioner_name
      # @param [Symbol] key
      # @param [Object] value
      def remove_instance_from_provisioner(provisioner_name, key, value)
        instances_for_provisioner(provisioner_name).delete_if do |instance|
          instance[key] == value
        end
      end

      # Persists the data to the Chef server
      def save
        data_bag_item.save
      end

      # Removes the data from the Chef server
      def destroy
        data_bag.item.delete environment_name
      end

      private

      def attributes
        data_bag_item.attributes
      end

      def data_bag
        @data_bag ||=
          ridley.data_bag.find(DATA_BAG) ||
          ridley.data_bag.create(name: DATA_BAG)
      end

      def data_bag_item
        @data_bag_item ||=
          data_bag.item.find(environment_name) ||
          data_bag.item.create(id: environment_name)
      end
    end
  end
end
