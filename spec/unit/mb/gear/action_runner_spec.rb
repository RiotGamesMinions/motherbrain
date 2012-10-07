require 'spec_helper'

describe MB::Gear::ActionRunner do
  let(:component) do
    MB::Component.new(@context) do
      group do
        name "master"
      end
    end
  end

  let(:gear) { double('gear', parent: component) }
  let(:action) { Proc.new { } }

  subject { MB::Gear::ActionRunner.new(gear, action) }

  describe "#on" do
    it "returns self" do
      subject.on("master").should eql(subject)
    end

    it "adds a group to the set of target groups" do
      subject.on("master").target_groups.should have(1).item
    end

    it "does not add duplicate target groups" do
      subject.on("master")
      subject.on("master")

      subject.target_groups.should have(1).item
    end

    context "given a group that is not part of the gear's parent" do
      it "raises a GroupNotFound error" do
        lambda {
          subject.on("not_exist")
        }.should raise_error(MB::GroupNotFound)
      end
    end
  end

  describe "#run" do
    pending
  end
end
