require 'spec_helper'

describe MB::Gear::Service do
  let(:component) { double('component', name: 'test-component') }

  describe "Class" do
    subject { MB::Gear::Service }

    it "is registered with MB::Gear" do
      MB::Gear.all.should include(subject)
    end

    it "has the inferred keyword ':service' from it's Class name" do
      subject.keyword.should eql(:service)
    end

    describe "::new" do
      it "sets the given name attribute" do
        obj = subject.new(@context, component) do
          name "activemq"
        end

        obj.name.should eql("activemq")
      end
    end
  end

  subject do
    MB::Gear::Service.new(@context, component) do
      # block
    end
  end

  describe "#actions" do
    subject do
      MB::Gear::Service.new(@context, component) do
        action :start do
          node_attribute("key.one", true)
        end

        action :stop do
          # block
        end
      end
    end

    it "returns a Set of Gear::Action::Service objects for each defined action" do
      subject.actions.should be_a(Set)
      subject.actions.should have(2).items
      subject.actions.should each be_a(MB::Gear::Service::Action)
    end
  end

  describe "#action" do
    subject do
      MB::Gear::Service.new(@context, component) do
        name "activemq"

        action :start do
          node_attribute("key.one", true)
        end
      end
    end

    it "returns a Gear::Service::Action" do
      subject.action(:start).should be_a(MB::Gear::Service::Action)
    end

    context "given an action that does not exist" do
      it "raises an ActionNotFound error" do
        lambda {
          subject.action(:stop)
        }.should raise_error(MB::ActionNotFound)
      end
    end
  end

  describe "#add_action" do
    let(:action_1) { double('action_1', name: "start") }
    let(:action_2) { double('action_2', name: "stop") }

    it "adds the given action to the set of actions" do
      subject.add_action(action_1)

      subject.actions.should have(1).item
      subject.action("start").should eql(action_1)
    end

    context "when an action of the given name has already been defined" do
      it "raises a DuplicateAction error" do
        lambda {
          subject.add_action(action_1)
          subject.add_action(action_1)
        }.should raise_error(MB::DuplicateAction)
      end
    end
  end

  describe MB::Gear::Service::Action do
    let(:action_name) { :start }

    let(:node_1) { double('node_1', name: 'reset.riotgames.com') }
    let(:node_2) { double('node_2', name: 'jwinsor.riotgames.com') }
    let(:node_3) { double('node_3', name: 'jwinsor-2.riotgames.com') }

    let(:master_group) do
      double('master_group',
        nodes: [
          node_1,
          node_2
        ]
      )
    end

    let(:slave_group) do
      double('slave_group',
        nodes: [
          node_1,
          node_2,
          node_3
        ]
      )
    end

    subject do
      MB::Gear::Service::Action.new(@context, action_name, component) do
        # block
      end
    end

    before(:each) do
      component.stub(:group).with("master").and_return(master_group)
      component.stub(:group).with("slave").and_return(slave_group)
    end

    describe "#on" do
      it "returns self" do
        subject.on("master").should eql(subject)
      end

      it "adds a group to the set of target groups" do
        subject.on("master").groups.should have(1).item
      end

      it "does not add duplicate target groups" do
        subject.on("master")
        subject.on("master")

        subject.groups.should have(1).item
      end

      context "given a group that is not part of the gear's parent" do
        before(:each) do
          component.stub(:group).with("not_exist").and_return(nil)
        end

        it "raises a GroupNotFound error" do
          lambda {
            subject.on("not_exist")
          }.should raise_error(MB::GroupNotFound)
        end
      end
    end

    describe "#nodes" do
      before(:each) do
        subject.on("master")
        subject.on("slave")
      end

      it "returns an array" do
        subject.nodes.should be_a(Array)
      end

      it "contains only the unique node elements from the component's group" do
        subject.nodes =~ master_group.nodes
        subject.nodes =~ slave_group.nodes
        subject.nodes.should have(3).items
      end
    end

    describe "#run" do
      it "returns true on success" do
        subject.run.should be_true
      end
    end
  end
end
