require 'spec_helper'

describe MB::InvokerBase do
  describe "ClassMethods" do
    subject { MB::InvokerBase }

    describe "default configuration path" do
      context "when the value of ENV['MB_CONFIG'] specifies a config file that exists" do
        before(:each) do
          set_mb_config_path(mb_config_path.join('config.json'))
          generate_valid_config(ENV['MB_CONFIG'])
        end

        after(:each) { FileUtils.rm(ENV['MB_CONFIG']) }

        it "reads the configuration file as the Invoker's configuration" do
          invoker = subject.new([])

          invoker.context.config.chef_api_url.should_not be_nil
        end
      end

      context "when a config.json is not found in the directory contained in ENV['MB_CONFIG']" do
        before(:each) do
          FileUtils.rm(ENV['MB_CONFIG'])
        end

        it "raises a Chozo::Errors::ConfigNotFound error configuration" do
          lambda {
            subject.new([])
          }.should raise_error(Chozo::Errors::ConfigNotFound)
        end
      end
    end

    describe "specifying a configuration file" do
      before(:each) do
        set_mb_config_path(mb_config_path.join('config.json'))
        generate_valid_config(ENV['MB_CONFIG'])
      end

      it "loads the specified config file when the specified file exists" do
        invoker = subject.new([], config: ENV['MB_CONFIG'])

        invoker.context.config.chef_api_url.should_not be_nil
      end

      it "raises a ConfigNotFound error when the specified path does not exist" do
        lambda {
          invoker = subject.new([], config: tmp_path.join("config.json"))
        }.should raise_error(Chozo::Errors::ConfigNotFound)
      end

      it "raises a ConfigNotFound error when the specified path is a directory" do
        lambda {
          invoker = subject.new([], config: tmp_path)
        }.should raise_error(Chozo::Errors::ConfigNotFound)
      end
    end
  end

  before(:each) do
    set_mb_config_path(mb_config_path.join('config.json'))
    generate_valid_config(ENV['MB_CONFIG'])
  end

  subject { MB::InvokerBase.new([], config: ENV['MB_CONFIG']) }

  describe "#context" do
    it "returns an instance of MB::Context" do
      subject.context.should be_a(MB::Context)
    end
  end
end
