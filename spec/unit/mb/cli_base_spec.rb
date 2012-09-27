require 'spec_helper'

describe MB::CliBase do
  describe "ClassMethods" do
    subject { MB::CliBase }

    describe "default configuration path" do
      context "when the value of ENV['MB_CONFIG'] specifies a config file that exists" do
        before(:each) do
          set_mb_config_path(mb_config_path)
          generate_config(ENV['MB_CONFIG'])
        end

        it "reads the configuration file as the Cli's configuration" do
          cli = subject.new([])

          cli.config.chef_api_url.should_not be_nil
        end
      end

      context "when a config.json is not found in the directory contained in ENV['MB_CONFIG']" do
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

  subject { MB::CliBase.new }

  describe "#plugin_loader" do
    it "returns an instance of PluginLoader" do
      subject.plugin_loader.should be_a(MB::PluginLoader)
    end

    it "has the same paths as the config.plugin_paths value" do
      subject.plugin_loader.paths.to_a.collect(&:to_s).should eql(subject.config.plugin_paths)
    end
  end
end
