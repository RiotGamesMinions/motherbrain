require 'spec_helper'

describe MB::Gear::DynamicService do
  let(:dynamic_service) { described_class.new('webapp', 'tomcat') }

  describe "ClassMethods" do
    subject { described_class }
    let(:service) { "webapp.tomcat" }

    describe "::parse_service" do
      it "splits the service on a period" do
        test_class = subject.parse_service(service)
        expect(test_class).to be_a(MB::Gear::DynamicService)
        expect(test_class.component).to eql('webapp')
        expect(test_class.name).to eql('tomcat')
      end
    end
  end

  describe "#async_state_change" do
  end

  describe "#set_node_attributes" do
    let(:set_node_attribute) { dynamic_service.set_node_attributes(job, nodes, attribute_key, state) }
    let(:job) { double(set_status: nil) }
    let(:nodes) { [ node1, node2 ] }
    let(:attribute_key) { "foo.bar" }
    let(:state) { "start" }
    let(:node1) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }
    let(:node2) { double(name: nil, reload: nil, set_chef_attribute: nil, save: nil) }

    it "sets a chef attribute on the node" do
      expect(node1).to receive(:set_chef_attribute).with("foo.bar", "start")
      set_node_attribute
    end
  end
end