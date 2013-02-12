require 'spec_helper'

describe MB::Invoker do
  describe "ClassMethods" do
    subject { MB::Invoker }

    describe "::new" do
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

    describe "::register_plugin" do
      let(:name) { "myface" }
      let(:version) { nil }
      let(:metadata) do
        double('metadata',
          valid?: true,
          name: name,
          description: "Ivey should use SublimeText 2"
        )
      end

      let(:plugin) { MB::Plugin.new(metadata) }
      let(:plugin_sub_command) { double(name: "#{name} sub command", plugin: name, version: version) }

      before(:each) do
        MB.ui.stub(:say)
      end

      context "with a version" do
        let(:version) { "1.2.3" }

        context "that doesn't exist" do
          before(:each) do
            MB::Application.stub_chain(:plugin_manager, :find).and_return(nil)
          end

          it "should notify the user" do
            MB.ui.should_receive(:say).with("No cookbook with myface (version 1.2.3) plugin was found in your Berkshelf.")
            lambda {
              subject.register_plugin name, version
            }.should raise_error(SystemExit)
          end
        end

        context "that exists" do
          before(:each) do
            MB::Cli::SubCommand.stub(:fabricate).and_return(plugin_sub_command)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
            plugin_sub_command.stub(:plugin).and_return(plugin)
          end

          it "should register the plugin" do
            subject.should_receive(:register)
            subject.register_plugin name, version
          end
        end
      end

      context "without a version" do
        context "that doesn't exist" do
          before(:each) do
            MB::Application.stub_chain(:plugin_manager, :find).and_return(nil)
          end

          it "should notify the user" do
            MB.ui.should_receive(:say).with("No cookbook with myface plugin was found in your Berkshelf.")
            lambda {
              subject.register_plugin name, version
            }.should raise_error(SystemExit)
          end
        end

        context "that exists" do
          before(:each) do
            MB::Cli::SubCommand.stub(:fabricate).and_return(plugin_sub_command)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
            plugin_sub_command.stub(:plugin).and_return(plugin)
          end

          it "should register the plugin" do
            subject.should_receive(:register)
            subject.register_plugin name, version
          end
        end
      end
    end
  end
end
