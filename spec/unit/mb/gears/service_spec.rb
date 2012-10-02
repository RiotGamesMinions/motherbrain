require 'spec_helper'

describe MB::Gear::Service do
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
        obj = subject.new do
          name "activemq"
        end

        obj.name.should eql("activemq")
      end

      context "when an action of the given name has already been defined" do
        it "raises a DuplicateAction error" do
          lambda {
            subject.new do
              action :start do; end
              action :start do; end
            end
          }.should raise_error(MB::DuplicateAction)
        end
      end
    end
  end

  subject do
    MB::Gear::Service.new do
      action :start do
        # block
      end

      action :stop do
        # block
      end
    end
  end

  describe "#actions" do
    it "returns a Hash of service names and procs for each action" do
      subject.actions.should be_a(Hash)
      subject.actions.should have(2).items
      subject.actions.should have_key(:start)
      subject.actions.should have_key(:stop)
      subject.actions[:start].should be_a(Proc)
      subject.actions[:stop].should be_a(Proc)
    end
  end

  describe "#action" do
    it "returns a proc for the given action" do
      subject.action(:start).should be_a(Proc)
    end
  end
end
