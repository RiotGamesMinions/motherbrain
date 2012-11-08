require 'spec_helper'

describe MotherBrain::PluginInvoker do
  describe "ClassMethods" do
    subject { Class.new(MB::PluginInvoker) }

    let(:name) { "pvpnet" }

    let(:commands) do
      [
        double('command_one', name: "start", description: "start stuff")
      ]
    end

    let(:components) do
      [
        double('component', name: "activemq", commands: commands, description: "activemq stuff")
      ]
    end

    let(:plugin) do
      double('plugin', name: name, commands: commands, components: components, bootstrapper: nil)
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
        tasks = subject.fabricate(plugin).tasks

        commands.each do |command|
          tasks.should include(command.name)
        end
      end

      it "creates a new subcommand for every component" do
        subcommands = subject.fabricate(plugin).subcommands

        subcommands.should have(components.length).items
        components.each do |component|
          subcommands.should include(component.name)
        end
      end

      context "when the plugin has a bootstrapper" do
        before(:each) do
          plugin.stub(:bootstrapper).and_return(double('bootstrapper'))
        end

        it "has a bootstrap task" do
          subject.fabricate(plugin).tasks.should have_key("bootstrap")
        end
      end

      context "when a plugin does not have a bootstrapper" do
        before(:each) do
          plugin.stub(:bootstrapper).and_return(nil)
        end

        it "does not have a bootstrap task" do
          subject.fabricate(plugin).tasks.should_not have_key("bootstrap")
        end
      end
    end
  end
end
