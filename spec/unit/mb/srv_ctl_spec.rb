require 'spec_helper'

describe MB::SrvCtl do
  describe "ClassMethods" do
    describe "::parse" do
      let(:args) { Array.new }
      let(:filename) { "mbsrv" }

      subject { described_class.parse(args, filename) }

      it "returns a hash" do
        subject.should be_a(Hash)
      end

      context "given -c" do
        let(:args) { ["-c", "/tmp/config.json"] }

        it "sets :config to the given value" do
          subject[:config].should eql("/tmp/config.json")
        end
      end

      context "given -k" do
        let(:args) { ["-k"] }

        it "sets :kill to true" do
          subject[:kill].should be_true
        end
      end

      context "given -v" do
        let(:args) { ["-v"] }

        it "sets :log_level to Logger::INFO" do
          subject[:log_level].should eql(Logger::INFO)
        end
      end

      context "given -D" do
        let(:args) { ["-D"] }

        it "sets :log_level to Logger::DEBUG" do
          subject[:log_level].should eql(Logger::DEBUG)
        end
      end

      context "given -D and -v" do
        let(:args) { ["-D", "-v"] }

        it "sets :log_level to Logger::DEBUG" do
          subject[:log_level].should eql(Logger::DEBUG)
        end
      end

      context "given -d" do
        let(:args) { ["-d"] }

        it "sets :daemonize to true" do
          subject[:daemonize].should be_true
        end
      end

      context "given -P" do
        let(:args) { ["-P", "/var/run/some.pid"] }

        it "sets :pid_file to the given value" do
          subject[:pid_file].should eql("/var/run/some.pid")
        end
      end

      context "given -P and -d" do
        let(:args) { ["-P", "/var/run/some.pid", "-d"] }

        it "sets :pid_file to the given value" do
          subject[:pid_file].should eql("/var/run/some.pid")
        end
      end
    end

    describe "::new" do
      before(:each) do
        generate_valid_config(MB::Config.default_path)
      end

      let(:options) { Hash.new }
      subject { described_class.new(options) }

      context "given no options" do
        it "sets a default value for :config" do
          subject.config.should_not be_nil
        end
      end

      context "given :daemonize is true" do
        let(:options) { { daemonize: true } }

        it "sets config.server.daemonize to true" do
          subject.config.server.daemonize.should be_true
        end
      end

      context "given a value for :pid_file" do
        let(:options) { { pid_file: "/tmp/some.pid" } }

        it "sets config.server.pid to the value" do
          subject.config.server.pid.should eql("/tmp/some.pid")
        end
      end

      context "given a value for :log_level" do
        let(:options) { { log_level: 'INFO' } }

        it "sets config.log.level to the value" do
          subject.config.log.level.should eql("INFO")
        end
      end

      context "given a value for :log_location" do
        let(:options) { { log_location: "/tmp/logs" } }

        it "sets config.log.location to the value" do
          subject.config.log.location.should eql("/tmp/logs")
        end
      end
    end
  end
end
