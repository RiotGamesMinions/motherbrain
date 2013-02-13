require 'spec_helper'

describe MB::CommandInvoker do
  let(:plugin_id) { "rspec-test" }
  let(:command_id) { "start" }
  let(:component_id) { "default" }
  let(:environment) { "rspec-testenv" }

  let(:options) do
    {
      version: "1.0.0"
    }
  end

  describe "#invoke_plugin" do
    context "when a plugin of the given name/version is not loaded" do
      before(:each) do
        plugin_manager.should_receive(:find).with(plugin_id, options[:version]).and_return(nil)
      end

      it "raises a PluginNotFound error" do
        expect {
          subject.invoke_plugin(plugin_id, command_id, environment, options)
        }.to raise_error(MB::PluginNotFound)
      end
    end

    context "when the plugin does not have the specified command" do
      let(:plugin) { double('plugin') }

      before(:each) do
        plugin_manager.should_receive(:find).with(plugin_id, options[:version]).and_return(plugin)
        plugin.should_receive(:command).with(command_id).and_return(nil)
      end

      it "raises a CommandNotFound error" do
        expect {
          subject.invoke_plugin(plugin_id, command_id, environment, options)
        }.to raise_error(MB::CommandNotFound)
      end
    end
  end

  describe "#invoke_component" do
    let(:plugin) { double('plugin', component: component) }
    let(:component) { double('component') }

    context "when a plugin of the given name/version is not loaded" do
      before(:each) do
        plugin_manager.should_receive(:find).with(plugin_id, options[:version]).and_return(nil)
      end

      it "raises a PluginNotFound error" do
        expect {
          subject.invoke_component(plugin_id, component_id, command_id, environment, options)
        }.to raise_error(MB::PluginNotFound)
      end
    end

    context "when the plugin does not have the specified component" do
      let(:plugin) { double('plugin') }

      before(:each) do
        plugin_manager.should_receive(:find).with(plugin_id, options[:version]).and_return(plugin)
        plugin.should_receive(:component).with(component_id).and_return(nil)
      end

      it "raises a ComponentNotFound error" do
        expect {
          subject.invoke_component(plugin_id, component_id, command_id, environment, options)
        }.to raise_error(MB::ComponentNotFound)
      end
    end

    context "when the component does not have the specified command" do
      before(:each) do
        plugin_manager.should_receive(:find).with(plugin_id, options[:version]).and_return(plugin)
        component.should_receive(:command).with(command_id).and_return(nil)
      end

      it "raises a CommandNotFound error" do
        expect {
          subject.invoke_component(plugin_id, component_id, command_id, environment, options)
        }.to raise_error(MB::CommandNotFound)
      end
    end
  end
end
