require 'spec_helper'

describe MB::Gear::Service do
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
  end
end
