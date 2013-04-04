require 'spec_helper'

describe MB::AbstractGear do
  subject do
    Class.new(MB::AbstractGear).new
  end

  describe "#run" do
    it "raises an AbstractFunction error when not implemented" do
      lambda {
        subject.run(double('job'), double('environment'))
      }.should raise_error(MB::AbstractFunction)
    end
  end
end
