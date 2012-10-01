require 'spec_helper'

describe MotherBrain::PluginInvoker do
  describe "ClassMethods" do
    subject { MB::PluginInvoker }

    let(:name) { "pvpnet" }

    let(:commands) do
      [
        double('command_one', name: "start", description: "start stuff")
      ]
    end

    let(:plugin) do
      double('plugin', name: name, commands: commands)
    end

    describe "::fabricate" do
      it "returns an anonymous class" do
        subject.fabricate(plugin).should be_a(Class)
      end

      it "sets the plugin class attribute to the given plugin" do
        subject.fabricate(plugin).plugin.should eql(plugin)
      end

      it "sets the namespace to the name of the given plugin" do
        subject.fabricate(plugin).namespace.should eql(plugin.name)
      end

      it "creates a task for each of the plugin's commands" do
        subject.fabricate(plugin).tasks.should have(commands.length).item
      end
    end
  end
end
