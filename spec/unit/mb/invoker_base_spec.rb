require 'spec_helper'

describe MB::InvokerBase do
  describe "ClassMethods" do
    subject { MB::InvokerBase }

    describe "specifying a configuration file" do
      let(:location) { tmp_path.join('config.json').to_s }

      before(:each) do
        generate_valid_config(location)
      end

      it "loads the specified config file when the specified file exists" do
        invoker = subject.new([], config: location)

        invoker.config.chef.api_url.should_not be_nil
      end

      it "raises a ConfigNotFound error when the specified path does not exist" do
        lambda {
          invoker = subject.new([], config: tmp_path.join("not_there.json"))
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
    generate_valid_config
  end

  subject { MB::InvokerBase.new([]) }

  describe "#config" do
    it "returns an instance of MB::Config" do
      subject.config.should be_a(MB::Config)
    end
  end
end
