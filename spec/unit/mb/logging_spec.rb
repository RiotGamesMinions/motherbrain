require 'spec_helper'

describe MotherBrain::Logging do
  describe "ClassMethods" do
    subject { MotherBrain::Logging }

    describe "::logger" do
      it "returns a Logger class" do
        subject.logger.should be_a(Logger)
      end
    end

    describe "::set_logger" do
      it "sets the logger to the given instance" do
        new_logger = Logger.new('/dev/null')
        subject.set_logger(new_logger)

        subject.logger.should eql(new_logger)
      end
    end
  end

  subject do
    Class.new do
      include MotherBrain::Logging
    end.new
  end

  describe "#logger" do
    it "delegates to MotherBrain::Logging.logger" do
      MotherBrain::Logging.should_receive(:logger)

      subject.logger
    end
  end
end
