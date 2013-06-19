module MotherBrain
  module Provisioner
    # Handles persisting provision data to a Chef server, for use later by
    # other provisioner actions on that environment.
    class ProvisionData
      include MB::Mixin::Services

      DATA_BAG = '_motherbrain_provision_data_'

      attr_reader :environment_name

      def initialize(environment_name)
        @environment_name = environment_name
      end

      def instances
        attributes[:instances] ||= []

        attributes[:instances]
      end

      def add_instances(instance_array)
        instance_array.each do |instance|
          instances.push instance unless instances.include?(instance)
        end
      end

      def remove_instance(key, value)
        instances.delete_if { |instance| instance[key] == value }
      end

      def provisioner_name
        attributes[:provisioner_name]
      end

      def provisioner_name=(value)
        attributes[:provisioner_name] = value
      end

      def save
        data_bag_item.save
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
