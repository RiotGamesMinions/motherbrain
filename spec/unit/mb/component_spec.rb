require 'spec_helper'

describe MB::Component do
  subject { MB::Component.new(:bacon) }

  describe "#groups" do
    it "returns an array of Group objects" do
      group = subject.group(:app) { }

      subject.groups.should be_a(Array)
      subject.groups.should include(group)
    end
  end

  describe "#group" do
    it "adds a new group to the component" do
      subject.group(:app) { }

      subject.groups.should have(1).item
    end

    it "raises a DuplicateGroup error if the group has already been defined" do
      subject.group(:app) { }

      lambda {
        subject.group(:app) { }
      }.should raise_error(MB::DuplicateGroup)
    end

    context "when no block is given" do
      before(:each) do
        subject.group(:reset) { }
      end

      it "returns the group matching the given name" do
        subject.group(:reset).name.should eql("reset")
      end
    end
  end
end
