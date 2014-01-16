require 'spec_helper'

describe MB::Gear::Service::ActionRunner do
  let(:environment) { "rspec" }
  let(:node_one) { double(name: 'node-one', save: nil) }
  let(:node_two) { double(name: 'node-two', save: nil) }
  let(:node_three) { Ridley::NodeObject.new(nil) }
  let(:job) { double(set_status: nil) }
  let(:nodes) { [ node_one, node_two ] }

  subject { action_runner }

  let(:action_runner) { MB::Gear::Service::ActionRunner.new(environment, nodes) }

  before do
    node_three.stub(:reload)
    node_three.stub(:save)
  end

  context "when an action describes a node attribute" do
    let(:action_runner) {
      MB::Gear::Service::ActionRunner.new(environment, nodes) do
        node_attribute('tester', true, toggle: true)
      end
    }

    it "has an item in the list of node attributes" do
      expect(action_runner.node_attributes).to have(1).item

      node_attribute = action_runner.node_attributes[0]
      expect(node_attribute).to be_a(Hash)
      expect(node_attribute[:key]).to eql('tester')
    end
  end

  context "when an action describes an environment attribute" do
    let(:action_runner) {
      MB::Gear::Service::ActionRunner.new(environment, nodes) do
        environment_attribute('tester', true, toggle: true)
      end      
    }

    it "has an item in the list of environment attributes" do
      expect(action_runner.environment_attributes).to have(1).item

      environment_attribute = action_runner.environment_attributes[0]
      expect(environment_attribute).to be_a(Hash)
      expect(environment_attribute[:key]).to eql('tester')
    end
  end

  context "when an action describes a service recipe" do
    let(:action_runner) {
      MB::Gear::Service::ActionRunner.new(environment, nodes) do
        service_recipe 'my_recipe'
      end
    }

    it "has a service recipe set" do
      expect(action_runner.service_recipe).to eql('my_recipe')
    end
  end

  describe "#add_environment_attribute" do
    let(:key) { "ruby.application.version" }
    let(:value) { "1.2.3" }
    let(:options) { Hash.new }

    it "adds an item to the list of #environment_attributes to set" do
      subject.add_environment_attribute(key, value, options)
      expect(subject.environment_attributes).to have(1).item
    end
  end

  describe "#add_node_attribute" do
    let(:key) { "ruby.application.version" }
    let(:value) { "1.2.3" }
    let(:options) { Hash.new }

    it "adds an item to the list of #node_attributes to set" do
      subject.add_node_attribute(key, value, options)
      expect(subject.node_attributes).to have(1).item
    end
  end

  describe "#set_node_attributes" do
    let(:nodes) { [ node_three ] }

    let(:set_node_attributes) { subject.send(:set_node_attributes, job) }

    context "when force_value_to and toggle are sent" do

      before do
        subject.add_node_attribute('some.attr', 123, toggle: true, force_value_to: 789)
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
      subject.add_environment_attribute('some.env.attr', 123, toggle: true)
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

    let(:reset) { subject.reset(job) }

    context "when the callback toggles a node attribute" do

      before do
        subject.add_node_attribute('some.attr', 123, toggle: true)
        subject.send(:set_node_attributes, job)
      end

      it "resets the original value" do
        node_three.should_receive(:set_chef_attribute).with('some.attr', nil)
        reset
      end
    end

    context "when the callback uses force_value_to on a node attribute" do

      before do
        subject.add_node_attribute('some.attr', 123, toggle: true, force_value_to: 789)
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
        subject.add_environment_attribute('some.env.attr', 123, toggle: true)
        subject.send(:set_environment_attributes, job)
      end

      it "removes the attribute key" do
        environment.should_receive(:delete_default_attribute).with('some.env.attr')
        reset
      end
    end
  end
end
