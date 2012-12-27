require 'spec_helper'

describe MB::DynamicInvoker do
  subject { Class.new(MB::DynamicInvoker) }

  describe ".fabricate" do
    it "raises an AbstractFunction error when not implemented" do
      lambda {
        subject.fabricate
      }.should raise_error(MB::AbstractFunction)
    end
  end
end
