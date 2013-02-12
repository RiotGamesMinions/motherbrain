require 'spec_helper'

describe MB::Invoker do
  describe "ClassMethods" do
    subject { MB::Invoker }

    describe ".register_plugin" do
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
      let(:plugin_invoker) { double(name: "#{name} invoker", plugin: name, version: version) }

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
            MB::PluginInvoker.stub(:fabricate).and_return(plugin_invoker)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
            plugin_invoker.stub(:plugin).and_return(plugin)
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
            MB::PluginInvoker.stub(:fabricate).and_return(plugin_invoker)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
            plugin_invoker.stub(:plugin).and_return(plugin)
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
