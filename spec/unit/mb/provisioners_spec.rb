require 'spec_helper'

describe MB::Provisioners do
  subject { MB::Provisioners }

  describe "::all" do
    it "returns a set" do
      subject.all.should be_a(Set)
    end
  end
end
