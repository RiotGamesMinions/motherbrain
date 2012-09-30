require 'spec_helper'

describe MotherBrain::PluginCLI do
  describe "ClassMethods" do
    subject { MB::PluginCLI }

    let(:plugin) do
      double('plugin', name: 'pvpnet')
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
    end
  end
end
