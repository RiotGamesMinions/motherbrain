require 'spec_helper'

describe MB::Gear::Service::ActionRunner do
  let(:environment) { "rspec" }
  let(:node_one) { double(name: 'node-one', save: nil) }
  let(:node_two) { double(name: 'node-two', save: nil) }
  let(:nodes) { [ node_one, node_two ] }

  subject { described_class.new(environment, nodes) }

  describe "#environment_attribute" do
    let(:key) { "ruby.application.version" }
    let(:value) { "1.2.3" }
    let(:options) { Hash.new }

    it "adds an item to the list of #environment_attributes to set" do
      subject.environment_attribute(key, value, options)
      expect(subject.send(:environment_attributes)).to have(1).item
    end
  end

  describe "#node_attribute" do
    let(:key) { "ruby.application.version" }
    let(:value) { "1.2.3" }
    let(:options) { Hash.new }

    it "adds an item to the list of #node_attributes to set" do
      subject.node_attribute(key, value, options)
      expect(subject.send(:node_attributes)).to have(1).item
    end
  end
end
