require 'spec_helper'

describe MotherBrain do
  subject { MotherBrain }

  describe "::ui" do
    it "returns an instance of Thor::Shell::Color" do
      subject.ui.should be_a(Thor::Shell::Color)
    end
  end

  describe "::root" do
    it "returns a pathname" do
      subject.root.should be_a(Pathname)
    end
  end

  describe "::logger" do
    it "delegates to MotherBrain::Logging.logger" do
      MotherBrain::Logging.should_receive(:logger)

      subject.logger
    end
  end

  describe "::set_logger" do
    it "delegates to MotherBrain::Logging.set_logger" do
      new_logger = Logger.new('/dev/null')
      MotherBrain::Logging.should_receive(:set_logger).with(new_logger)

      subject.set_logger(new_logger)
    end
  end
end
