require 'spec_helper'

describe MB::DynamicInvoker do
  describe "ClassMethods" do
    subject do
      Class.new(MB::DynamicInvoker)
    end

    describe "::fabricate" do
      it "raises an AbstractFunction error when not implemented" do
        lambda {
          subject.fabricate
        }.should raise_error(MB::AbstractFunction)
      end
    end
  end
end
