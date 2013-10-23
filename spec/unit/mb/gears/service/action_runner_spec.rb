require 'spec_helper'

describe MB::Gear::Service::ActionRunner do
  let(:environment) { "rspec" }
  let(:node_one) { double(name: 'node-one', save: nil) }
  let(:node_two) { double(name: 'node-two', save: nil) }
  let(:node_three) { Ridley::NodeObject.new(nil) }
  let(:job) { double(set_status: nil) }
  let(:nodes) { [ node_one, node_two ] }

  subject { described_class.new(environment, nodes) }

  before do
    node_three.stub(:reload)
    node_three.stub(:save)
  end

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

  describe "#set_node_attributes" do
    let(:nodes) { [ node_three ] }

    let(:set_node_attributes) { subject.send(:set_node_attributes, job) }

    context "when force_value_to and toggle are sent" do

      before do
        subject.node_attribute('some.attr', 123, toggle: true, force_value_to: 789)
      end

      it "sets the node attribute" do
        node_three.should_receive(:set_chef_attribute).with('some.attr', 123)
        set_node_attributes
      end

      it "adds a callback" do
        set_node_attributes
        expect(subject.toggle_callbacks.size).to eql(1)
      end
    end
  end

  describe "#set_environment_attributes" do
    let(:environment) { Ridley::EnvironmentObject.new(nil) }
    let(:ridley) { double( 'foo', environment: environment_resource) }
    let(:environment_resource) { double(find: environment) }
    let(:set_environment_attributes) { subject.send(:set_environment_attributes, job) }

    before do
      subject.environment_attribute('some.env.attr', 123, toggle: true)
      MB::Application.stub(:[]).and_return(ridley)
      environment.stub(:save)
    end

    it "sets the environment attribute" do
      environment.should_receive(:set_default_attribute).with('some.env.attr', 123)
      set_environment_attributes
    end

    it "adds a callback" do
      set_environment_attributes
      expect(subject.toggle_callbacks.size).to eql(1)
    end
  end

  describe "#reset" do
    let(:nodes) { [ node_three ] }

    let(:reset) { subject.send(:reset, job) }

    context "when the callback toggles a node attribute" do

      before do
        subject.node_attribute('some.attr', 123, toggle: true)
        subject.send(:set_node_attributes, job)
      end

      it "resets the original value" do
        node_three.should_receive(:set_chef_attribute).with('some.attr', nil)
        reset
      end
    end

    context "when the callback uses force_value_to on a node attribute" do

      before do
        subject.node_attribute('some.attr', 123, toggle: true, force_value_to: 789)
        subject.send(:set_node_attributes, job)
      end

      it "sets the attribute to the forced value" do
        node_three.should_receive(:set_chef_attribute).with('some.attr', 789)
        reset
      end
    end

    context "when the callback toggles an environment attribute" do
      let(:environment) { Ridley::EnvironmentObject.new(nil) }
      let(:ridley) { double( 'foo', environment: environment_resource) }
      let(:environment_resource) { double(find: environment) }


      before do
        MB::Application.stub(:[]).and_return(ridley)
        environment.stub(:save)
        subject.environment_attribute('some.env.attr', 123, toggle: true)
        subject.send(:set_environment_attributes, job)
      end

      it "removes the attribute key" do
        environment.should_receive(:delete_default_attribute).with('some.env.attr')
        reset
      end
    end
  end
end
