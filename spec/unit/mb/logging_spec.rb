require 'spec_helper'

describe MB::Logging do
  before :each do
    klass.reset
  end

  describe "ClassMethods" do
    subject { MB::Logging }

    describe "::logger" do
      it "returns a Logger class" do
        subject.logger.should be_a(Logger)
      end
    end

    describe "::setup" do
      subject(:logger) { MB::Logging.logger }

      let(:options) { Hash.new }

      it "remembers options when called multiple times" do
        klass.setup level: Logger::DEBUG, location: STDERR
        klass.setup Hash.new

        logger.instance_variable_get(:@logdev).dev.should == STDERR
        logger.debug?.should be_true
      end

      before :each do
        klass.setup options
      end

      it "defaults to WARN" do
        logger.warn?.should be_true
      end

      context "with level: INFO" do
        let(:options) { { level: Logger::INFO } }

        its(:info?) { should be_true }
      end

      context "with level: Logger::DEBUG" do
        let(:options) { { level: Logger::DEBUG } }

        its(:debug?) { should be_true }
      end

      it "defaults to STDOUT" do
        logger.instance_variable_get(:@logdev).dev.should == STDOUT
      end

      context "when passed STDOUT as a string" do
        let(:options) { { location: "STDOUT" } }

        it "constantizes STDOUT" do
          logger.instance_variable_get(:@logdev).dev.should == STDOUT
        end
      end

      context "when passed STDERR as a string" do
        let(:options) { { location: "STDERR" } }

        it "constantizes STDERR" do
          logger.instance_variable_get(:@logdev).dev.should == STDERR
        end
      end

      context "with a path" do
        let(:location) { File.join tmp_path, "log.txt" }
        let(:options) { { location: location } }

        it "logs to the path" do
          logger.instance_variable_get(:@logdev).dev.path.should == location
        end
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
