require 'spec_helper'

describe MB::CliGateway do
  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      describe "specifying a configuration file" do
        let(:location) { tmp_path.join('config.json').to_s }

        before(:each) do
          generate_valid_config(location)
        end

        it "loads the specified config file into the ConfigManager" do
          config = MB::Config.from_file(location)
          invoker = subject.new([], config: location)

          MB::ConfigManager.instance.config._attributes_.should eql(config._attributes_)
        end

        it "exits with a ConfigNotFound error when the specified path does not exist" do
          lambda {
            invoker = subject.new([], config: tmp_path.join("not_there.json"))
          }.should exit_with(MB::ConfigNotFound)
        end

        it "exits with a ConfigNotFound error when the specified path is a directory" do
          lambda {
            invoker = subject.new([], config: tmp_path)
          }.should exit_with(MB::ConfigNotFound)
        end
      end
    end

    describe "::requires_environment?" do
      context "no arguments" do
        it "should not require an environment" do
          subject.requires_environment?([]).should be_false
        end
      end

      context "base command" do
        ["destroy", "lock", "unlock"].each do |command|
          it "should require an environment for #{command}" do
            subject.requires_environment?([command]).should be_true
          end
        end

        it "should require an environment for configure_environment" do
          subject.requires_environment?(["configure_environment", "manifest"]).should be_true
        end

        it "should not require an environment for versions" do
          subject.requires_environment?(["versions"]).should be_false
        end
      end

      context "plugin argument" do
        it "should not require an environment for a plugin" do
          subject.requires_environment?(["myface"]).should be_false
        end
      end
      
      context "plugin command" do
        it "should require an environment for bootstrap" do
          subject.requires_environment?(["myface", "bootstrap"]).should be_true
        end

        it "should not require an environment for help" do
          subject.requires_environment?(["myface", "help"]).should be_false
        end

        it "should not require an environment for subtask help" do
          subject.requires_environment?(["myface", "help", "bootstrap"]).should be_false
        end
      end
    end

    describe "::start_mb_application?" do
      let(:args) {["myface"]}

      context "not a config task" do
        it "should be true" do
          subject.start_mb_application?(args).should be_true
        end
      end

      context "is a config task" do
        it "should be false" do
          subject::SKIP_CONFIG_TASKS.each do |config_task|
            args = [config_task]
            subject.start_mb_application?(args)
          end
        end
      end
    end

    describe "::register_plugin" do
      let(:name) { "myface" }
      let(:description) { "Ivey should use SublimeText 2" }
      let(:plugin) { MB::Plugin.new(metadata) }
      let(:metadata) do
        double('metadata',
          valid?: true,
          name: name,
          description: description
        )
      end

      it "registers a subcommand with self" do
        subcommand = double
        MB::Cli::SubCommand.should_receive(:new).with(plugin).and_return(subcommand)
        subject.should_receive(:register_subcommand).with(subcommand)

        subject.register_plugin(plugin)
      end

      it "returns a subcommand with the plugin set as #plugin" do
        subject.register_plugin(plugin).plugin.should eql(plugin)
      end

      it "has a name matching the plugin" do
        subject.register_plugin(plugin).name.should eql(name)
      end

      it "has a description matching the plugin" do
        subject.register_plugin(plugin).description.should eql(description)
      end
    end

    describe "::find_plugin" do
      let(:plugin_manager) { double('plugin_manager') }
      let(:name) { "myface" }
      let(:options) do
        {
          plugin_version: nil,
          environment: nil
        }
      end
      let(:plugin) { double('asdf') }
      let(:ui) { described_class.ui }

      subject { described_class.find_plugin(name, options) }
      before { described_class.stub(plugin_manager: plugin_manager) }

      context "given no value for :plugin_version or :environment" do
        before do
          options[:plugin_version] = nil
          options[:environment] = nil
        end

        it "finds the installed or remote latest version of the plugin with the given name" do
          plugin_manager.should_receive(:latest).with(name, remote: true).and_return(plugin)

          subject.should eql(plugin)
        end

        it "prints an error to the UI and exits if no plugin is found" do
          plugin_manager.should_receive(:latest).with(name, remote: true).and_return(nil)
          ui.should_receive(:error).with(anything)

          expect {
            subject
          }.to raise_error(SystemExit)
        end
      end

      context "given a value for :plugin_version" do
        let(:plugin_version) { "1.2.3" }
        before { options[:plugin_version] = plugin_version }

        it "finds a plugin on local and remote of the given name and version" do
          plugin_manager.should_receive(:find).with(name, plugin_version, remote: true).and_return(plugin)

          subject.should eql(plugin)
        end

        it "prints an error to the UI and exits if no plugin is found" do
          plugin_manager.should_receive(:find).with(name, plugin_version, remote: true).and_return(nil)
          ui.should_receive(:error).with(anything)

          expect {
            subject
          }.to raise_error(SystemExit)
        end
      end

      context "given a value for :environment" do
        let(:environment) { "rspec-test" }
        before { options[:environment] = environment }

        it "finds the best suitable plugin for the environment" do
          plugin_manager.should_receive(:for_environment).with(name, environment, remote: true).and_return(plugin)

          subject.should eql(plugin)
        end

        context "when an environment of the given name is not found" do
          before do
            plugin_manager.should_receive(:for_environment).and_raise(MB::EnvironmentNotFound.new(environment))
          end

          it "finds the latest plugin on local and remote of the given name" do
            plugin_manager.should_receive(:latest).with(name, remote: true).and_return(plugin)

            subject.should eql(plugin)
          end

          it "prints an error to the UI and exits if no plugin is found" do
            plugin_manager.should_receive(:latest).with(name, remote: true).and_return(nil)

            expect {
              subject
            }.to raise_error(SystemExit)
          end
        end
      end
    end
  end
end
