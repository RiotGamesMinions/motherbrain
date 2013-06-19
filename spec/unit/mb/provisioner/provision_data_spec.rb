require 'spec_helper'

describe MotherBrain::Provisioner::ProvisionData do
  subject { provision_data }

  let(:provision_data) { described_class.new(environment_name) }

  let(:data_bag) { ridley.data_bag.find(described_class::DATA_BAG) }
  let(:data_bag_attributes) { data_bag_item.attributes }
  let(:data_bag_item) { data_bag.item.find(environment_name) }
  let(:environment_name) { "test" }
  let(:instances) {
    [
      {
        instance_id: "i-abcdefb1",
        instance_type: "m1.large",
        public_hostname: "box1.cloud.example.com"
      },
      {
        instance_id: "i-abcdefb2",
        instance_type: "m1.large",
        public_hostname: "box2.cloud.example.com"
      }
    ]
  }
  let(:provisioner_name) { "aws" }

  describe "#instances" do
    it "returns an empty array by default" do
      expect(provision_data.instances).to eq([])
    end

    it "saves an empty array to the data bag" do
      provision_data.instances

      provision_data.save

      expect(data_bag_attributes[:instances]).to match_array([])
    end
  end

  describe "#add_instances" do
    it "adds the instances to the data bag" do
      provision_data.add_instances instances

      provision_data.save

      expect(
        data_bag_attributes[:instances].map(&:to_hash)
      ).to match_array(instances)
    end

    it "is idempotent" do
      provision_data.add_instances instances
      provision_data.add_instances instances

      provision_data.save

      expect(
        data_bag_attributes[:instances].map(&:to_hash)
      ).to match_array(instances)
    end
  end

  describe "#remove_instance" do
    it "removes an instance by key/value pair" do
      provision_data.add_instances instances
      provision_data.remove_instance :instance_id, instances.first[:instance_id]

      expect(provision_data.instances).to match_array([instances.last])
    end
  end

  describe "#provisioner_name" do
    it "returns the provisioner name from the data bag" do
      provision_data.save

      data_bag_attributes[:provisioner_name] = provisioner_name
      data_bag_item.save

      provision_data.instance_variable_set :@data_bag_item, nil

      expect(provision_data.provisioner_name).to eq(provisioner_name)
    end
  end

  describe "#provisioner_name=" do
    it "sets the provisioner name" do
      provision_data.provisioner_name = provisioner_name

      expect(provision_data.provisioner_name).to eq(provisioner_name)
    end

    it "persists to the data bag" do
      provision_data.provisioner_name = provisioner_name

      provision_data.save

      expect(data_bag_attributes[:provisioner_name]).to eq(provisioner_name)
    end
  end

  describe "#save" do
    it "creates a data bag item" do
      provision_data.save

      expect(data_bag_item).to_not be_nil
    end
  end
end
