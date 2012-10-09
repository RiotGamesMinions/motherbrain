require 'spec_helper'

describe MB::ChefRunner do
  describe "ClassMethods" do
    subject { MB::ChefRunner }

    describe "::validate_options" do
      let(:options) { double('options') }

      it "returns true if the options are valid" do
        subject.validate_options(options).should be_true
      end
    end
  end

  let(:automatic_attributes) do
    HashWithIndifferentAccess.new(ipaddress: "33.33.33.10")
  end

  let(:node) do
    double('node', automatic: automatic_attributes)
  end

  subject { MB::ChefRunner.new }

  describe "#add_node" do
    it "returns a Rye::Set" do
      subject.add_node(node).should be_a(Rye::Set)
    end

    it "adds a nodes to the list of nodes" do
      subject.add_node(node)

      subject.nodes.should have(1).item
    end

    context "given a node that does not have a value for ipaddress at the given address_attribute" do
      subject { MB::ChefRunner.new(address_attribute: 'network.en0.ipaddress') }

      it "raises an error" do
        lambda {
          subject.add_node(node)
        }.should raise_error(MB::NoValueForAddressAttribute)
      end
    end
  end
end
