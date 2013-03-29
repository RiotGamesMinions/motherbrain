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
        plugin_manager.should_receive(:for_environment).with(plugin_id, environment)
          .and_raise(MB::PluginNotFound.new(plugin_id))
      end

      it "completes the job as a failure" do
        job = subject.invoke_plugin(plugin_id, command_id, environment, options)

        job.should complete_as(:failure, "[err_code]: 3003 [message]: No plugin named 'rspec-test' found")
      end
    end

    context "when the plugin does not have the specified command" do
      let(:plugin) { double('plugin') }

      before(:each) do
        plugin_manager.should_receive(:for_environment).with(plugin_id, environment).and_return(plugin)
        plugin.should_receive(:command!).with(command_id).and_raise(MB::CommandNotFound.new(command_id, plugin))
      end

      it "completes the job as a failure" do
        job = subject.invoke_plugin(plugin_id, command_id, environment, options)

        job.should complete_as(:failure)
      end
    end
  end

  describe "#invoke_component" do
    let(:plugin) { double('plugin') }
    let(:component) { double('component') }

    context "when a plugin of the given name/version is not loaded" do
      before(:each) do
        plugin_manager.should_receive(:for_environment).with(plugin_id, environment).
          and_raise(MB::PluginNotFound.new(plugin_id))
      end

      it "completes the job as a failure" do
        job = subject.invoke_component(plugin_id, component_id, command_id, environment, options)

        job.should complete_as(:failure)
      end
    end

    context "when the plugin does not have the specified component" do
      let(:plugin) { double('plugin') }

      before(:each) do
        plugin_manager.should_receive(:for_environment).with(plugin_id, environment).and_return(plugin)
        plugin.should_receive(:component!).with(component_id).and_raise(MB::ComponentNotFound.new(component_id, plugin))
      end

      it "completes the job as a failure" do
        job = subject.invoke_component(plugin_id, component_id, command_id, environment, options)

        job.should complete_as(:failure)
      end
    end

    context "when the component does not have the specified command" do
      before(:each) do
        plugin_manager.should_receive(:for_environment).with(plugin_id, environment).and_return(plugin)
        plugin.should_receive(:component!).with(component_id).and_return(component)
        component.should_receive(:command!).with(command_id).and_raise(MB::CommandNotFound.new(command_id, plugin))
      end

      it "completes the job as a failure" do
        job = subject.invoke_component(plugin_id, component_id, command_id, environment, options)

        job.should complete_as(:failure)
      end
    end
  end
end
