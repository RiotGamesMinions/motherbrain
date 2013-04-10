require 'spec_helper'

describe MB::Mixin::CodedExit do
  subject do
    Class.new do
      include MB::Mixin::CodedExit
    end.new
  end

  describe "#exit_with" do
    let(:constant) { MB::MBError }

    it "exits with the status code for the given constant" do
      expect {
        subject.exit_with(constant)
      }.to exit_with(constant)
    end
  end

  describe "#exit_code_for" do
    it "returns the exit status for the given constant" do
      subject.exit_code_for("MBError").should eql(1)
    end
  end
end
