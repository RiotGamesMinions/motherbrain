require 'spec_helper'

describe MB::Gear::Service do
  let(:component) { double('component', name: 'test-component') }
  let(:job) { double('job', set_status: nil) }

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
        obj = subject.new(component, "activemq") do
          # block
        end

        obj.name.should eql("activemq")
      end
    end
  end

  subject do
    MB::Gear::Service.new("service", component) do
      # block
    end
  end

  describe "#actions" do
    subject do
      MB::Gear::Service.new("service", component) do
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

  describe "#action!" do
    subject do
      MB::Gear::Service.new("activemq", component) do
        action :start do
          node_attribute("key.one", true)
        end
      end
    end

    it "returns a Gear::Service::Action" do
      subject.action!(:start).should be_a(MB::Gear::Service::Action)
    end

    context "given an action that does not exist" do
      it "raises an ActionNotFound error" do
        lambda {
          subject.action!(:stop)
        }.should raise_error(MB::ActionNotFound)
      end
    end
  end

  describe "#action" do
    subject do
      MB::Gear::Service.new("activemq", component) do
        action :start do
          node_attribute("key.one", true)
        end
      end
    end

    it "returns a Gear::Service::Action" do
      subject.action(:start).should be_a(MB::Gear::Service::Action)
    end

    context "given an action that does not exist" do
      it "returns nil" do
        expect(subject.action(:stop)).to be_nil
      end

      it "does not raise an ActionNotFound error" do
        lambda {
          subject.action(:stop)
        }.should_not raise_error
      end
    end
  end

  describe "#add_action" do
    let(:action_1) { double('action_1', name: "start") }
    let(:action_2) { double('action_2', name: "stop") }

    it "adds the given action to the set of actions" do
      subject.add_action(action_1)

      subject.actions.should have(1).item
      subject.action!("start").should eql(action_1)
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

end
