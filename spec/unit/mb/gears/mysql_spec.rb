require 'spec_helper'

describe MB::Gear::MySQL do
  subject { described_class }

  it "is registered with MB::Gear" do
    MB::Gear.all.should include(subject)
  end

  it "has the inferred keyword ':mysql' from it's Class name" do
    subject.keyword.should eql(:mysql)
  end

  describe "#action" do
    subject { described_class.new }

    it "returns a Gear::MySQL::Action" do
      subject.action("select * from boxes", data_bag: {name: "creds"}).should be_a(MB::Gear::MySQL::Action)
    end
  end
end
