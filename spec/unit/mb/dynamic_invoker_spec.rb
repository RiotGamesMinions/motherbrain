require 'spec_helper'

describe MotherBrain::DynamicInvoker do
  describe "ClassMethods" do
    subject do
      Class.new do
        include MotherBrain::DynamicInvoker
      end
    end

    describe "::fabricate" do
      it "raises an AbstractFunction error when not implemented" do
        lambda {
          subject.fabricate
        }.should raise_error(MotherBrain::AbstractFunction)
      end
    end
  end
end
