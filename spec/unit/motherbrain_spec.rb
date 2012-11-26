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
    it "delegates to MB::Logging.logger" do
      MB::Logging.should_receive(:logger)

      subject.logger
    end
  end

  describe "::set_logger" do
    it "delegates to MB::Logging.set_logger" do
      new_logger = Logger.new('/dev/null')
      MB::Logging.should_receive(:set_logger).with(new_logger)

      subject.set_logger(new_logger)
    end
  end

  describe "::expand_procs" do
    it "returns an array of arrays containing the result of the evaluated procs" do
      procs = [
        -> { :one },
        -> { :two },
        [
          -> { :nested },
          [
            -> { :deep_nested }
          ]
        ]
      ]
      result = subject.expand_procs(procs)

      result.should have(3).items
      result[0].should eql(:one)
      result[1].should eql(:two)
      result[2].should have(2).items
      result[2][0].should eql(:nested)
      result[2][1].should have(1).item
      result[2][1][0].should eql(:deep_nested)
    end
  end
end
