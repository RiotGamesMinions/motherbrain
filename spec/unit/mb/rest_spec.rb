require 'spec_helper'

describe MB::REST do
  describe "::gateway" do
    it "returns an instance of MB::REST::Gateway" do
      subject.gateway.should be_a(MB::REST::Gateway)
    end
  end
end
