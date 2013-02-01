require 'spec_helper'

describe MB::Invoker do
  describe "ClassMethods" do
    subject { MB::Invoker }

    describe ".load_plugin" do
      let(:name) { "myface" }
      let(:version) { nil }
      let(:plugin) { double(name: name, version: version) }
      let(:plugin_invoker) { double(name: "#{name} invoker", plugin: name, version: version) }

      context "when user is listing plugins" do
        it "doesn't talk to plugin manager" do
          MB::Application.should_not_receive(:plugin_manager)
          subject.load_plugin "plugins"
        end

        it "doesn't load any plugins" do
          subject.load_plugin "plugins"
          MB::Application.plugin_manager.list(false).should be_empty
        end
      end

      context "with a version" do
        let(:version) { "1.2.3" }

        context "that doesn't exist" do
          before(:each) do
            MB::Application.stub_chain(:plugin_manager, :find).and_return(nil)
          end

          it "should notify the user" do
            MB.ui.should_receive(:say).with("Cookbook myface (version 1.2.3) not found. Install it with `berks install`")
            subject.load_plugin name, version
          end
        end

        context "that exists" do
          before(:each) do
            MB::PluginInvoker.stub(:fabricate).and_return(plugin_invoker)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
          end

          it "should register the plugin" do
            subject.should_receive(:register_plugin)
            subject.load_plugin name, version
          end
        end
      end

      context "without a version" do
        context "that doesn't exist" do
          before(:each) do
            MB::Application.stub_chain(:plugin_manager, :find).and_return(nil)
          end

          it "should notify the user" do
            MB.ui.should_receive(:say).with("Cookbook myface not found. Install it with `berks install`")
            subject.load_plugin name, version
          end
        end

        context "that exists" do
          before(:each) do
            MB::PluginInvoker.stub(:fabricate).and_return(plugin_invoker)
            MB::Application.stub_chain(:plugin_manager, :find).and_return(plugin)
          end

          it "should register the plugin" do
            subject.should_receive(:register_plugin)
            subject.load_plugin name, version
          end
        end
      end
    end
  end
end
