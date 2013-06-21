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
    it "returns an empty hash by default" do
      expect(provision_data.instances).to eq({})
    end

    it "saves an empty hash to the data bag" do
      provision_data.instances

      provision_data.save

      expect(data_bag_attributes[:instances]).to eq({})
    end
  end

  describe "#add_instances_to_provisioner" do
    it "adds the instances to the data bag" do
      provision_data.add_instances_to_provisioner provisioner_name, instances

      provision_data.save

      expect(
        data_bag_attributes[:instances][provisioner_name].map(&:to_hash)
      ).to match_array(instances)
    end

    it "is idempotent" do
      provision_data.add_instances_to_provisioner provisioner_name, instances
      provision_data.add_instances_to_provisioner provisioner_name, instances

      provision_data.save

      expect(
        data_bag_attributes[:instances][provisioner_name].map(&:to_hash)
      ).to match_array(instances)
    end
  end

  describe "#remove_instance_from_provisioner" do
    it "removes an instance from a provisioner by key/value pair" do
      provision_data.add_instances_to_provisioner provisioner_name, instances
      provision_data.remove_instance_from_provisioner provisioner_name,
        :instance_id, instances.first[:instance_id]

      expect(provision_data.instances[provisioner_name]).to match_array([instances.last])
    end
  end

  describe "#provisioners" do
    it "lists all provisioners with instances for this environment" do
      provision_data.add_instances_to_provisioner provisioner_name, instances

      expect(provision_data.provisioners).to match_array([provisioner_name])
    end
  end

  describe "#instances_for_provisioner" do
    it "returns an empty array by default" do
      expect(provision_data.instances_for_provisioner(:aws)).to eq([])
    end

    it "returns all instances for a provisioner" do
      provision_data.add_instances_to_provisioner provisioner_name, instances

      expect(
        provision_data.instances_for_provisioner(:aws)
      ).to match_array(instances)
    end
  end

  describe "#save" do
    it "creates a data bag item" do
      provision_data.save

      expect(data_bag_item).to_not be_nil
    end
  end

  describe "#destroy" do
    it "creates a data bag item" do
      provision_data.save
      provision_data.destroy

      expect(data_bag_item).to be_nil
    end
  end
end
