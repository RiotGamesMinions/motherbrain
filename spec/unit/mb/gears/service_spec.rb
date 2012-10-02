require 'spec_helper'

describe MB::Gear::Service do
  subject { MB::Gear::Service }

  it "is registered with MB::Gear" do
    MB::Gear.all.should include(subject)
  end

  it "has the inferred keyword ':service' from it's Class name" do
    subject.keyword.should eql(:service)
  end
end
