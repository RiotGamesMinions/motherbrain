require 'spec_helper'

describe MB::Logging do
  describe "ClassMethods" do
    subject { MB::Logging }

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
      include MB::Logging
    end.new
  end

  describe "#logger" do
    it "delegates to MB::Logging.logger" do
      MB::Logging.should_receive(:logger)

      subject.logger
    end
  end
end
