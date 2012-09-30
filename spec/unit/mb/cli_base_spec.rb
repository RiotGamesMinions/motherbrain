require 'spec_helper'

describe MB::CliBase do
  describe "ClassMethods" do
    subject { MB::CliBase }

    describe "default configuration path" do
      context "when the value of ENV['MB_CONFIG'] specifies a config file that exists" do
        before(:each) do
          set_mb_config_path(mb_config_path.join('config.json'))
          generate_config(ENV['MB_CONFIG'])
        end

        after(:each) { FileUtils.rm(ENV['MB_CONFIG']) }

        it "reads the configuration file as the Cli's configuration" do
          cli = subject.new([])

          cli.config.chef_api_url.should_not be_nil
        end
      end

      context "when a config.json is not found in the directory contained in ENV['MB_CONFIG']" do
        before(:each) do
          FileUtils.rm(ENV['MB_CONFIG'])
        end

        it "reads the configuration file as the Cli's configuration" do
          cli = subject.new([])

          cli.config.chef_api_url.should eql("http://localhost:8080")
        end
      end
    end

    describe "specifying a configuration file" do
      before(:each) do
        set_mb_config_path(mb_config_path.join('config.json'))
        generate_config(ENV['MB_CONFIG'])
      end

      it "loads the specified config file when the specified file exists" do
        cli = subject.new([], config: ENV['MB_CONFIG'])

        cli.config.chef_api_url.should_not be_nil
      end

      it "raises a ConfigNotFound error when the specified path does not exist" do
        lambda {
          cli = subject.new([], config: tmp_path.join("config.json"))
        }.should raise_error(Chozo::Errors::ConfigNotFound)
      end

      it "raises a ConfigNotFound error when the specified path is a directory" do
        lambda {
          cli = subject.new([], config: tmp_path)
        }.should raise_error(Chozo::Errors::ConfigNotFound)
      end
    end
  end

  before(:each) do
    set_mb_config_path(mb_config_path.join('config.json'))
    generate_config(ENV['MB_CONFIG'])
  end

  subject { MB::CliBase.new([], config: ENV['MB_CONFIG']) }

  describe "#chef_conn" do
    it "returns an instance of Ridley::Connection" do
      subject.chef_conn.should be_a(Ridley::Connection)
    end
  end
end
