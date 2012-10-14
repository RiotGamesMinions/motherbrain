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
        obj = subject.new(component) do
          name "activemq"
        end

        obj.name.should eql("activemq")
      end

      context "when an action of the given name has already been defined" do
        it "raises a DuplicateAction error" do
          lambda {
            subject.new(component) do
              action :start do; end
              action :start do; end
            end
          }.should raise_error(MB::DuplicateAction)
        end
      end
    end
  end

  subject do
    MB::Gear::Service.new(component) do
      action :start do
        node_attribute("key.one", true)
      end

      action :stop do
        # block
      end
    end
  end

  describe "#actions" do
    it "returns a Set of Gear::Action::Service objects for each defined action" do
      subject.actions.should be_a(Set)
      subject.actions.should have(2).items
      subject.actions.should each be_a(MB::Gear::Service::Action)
    end
  end

  describe "#action" do
    subject do
      MB::Gear::Service.new(component) do
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

  describe "#node_attribute" do
    pending
  end

  describe MB::Gear::Service::Action do
    let(:id) { :start }
    subject { MB::Gear::Service::Action.new(component, id) }

    before(:each) do
      component.stub(:group).with("master").and_return(double('master_group'))
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
  end
end
