require 'spec_helper'

describe MB::SafeReturn do
  subject { described_class }

  describe "#status" do
    it "returns the status" do
      subject.new(:ok, nil).status.should eql(:ok)
    end
  end

  describe "#body" do
    it "returns the body" do
      subject.new(:ok, "hello").body.should eql("hello")
    end
  end

  describe "#error?" do
    it "returns false if the status is not ':error'" do
      subject.new(:ok, nil).should_not be_error
    end

    it "returns true if a value is set in index 0 that is ':error'" do
      subject.new(:error, nil).should be_error
    end
  end

  describe "#ok?" do
    it "returns true if the status is ':ok'" do
      subject.new(:ok, nil).should be_ok
    end

    it "returns false if the status is not ':ok'" do
      subject.new(:error, nil).should_not be_ok
    end
  end
end
