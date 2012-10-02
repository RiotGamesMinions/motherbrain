require 'spec_helper'

describe MB::Gear::Service do
  subject { MB::Gear::Service }

  it "is registered with MB::Gear" do
    MB::Gear.all.should include(subject)
  end
end
