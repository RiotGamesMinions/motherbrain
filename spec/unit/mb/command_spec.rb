require 'spec_helper'

describe MB::Command do
  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      let(:name) { "stop" }
      let(:scope) { double }
      let(:plugin) { MB::Plugin.new(double(valid?: true)) }
      let(:component) { MB::Component.new("default", plugin) }

      subject { described_class.new(name, scope) }

      context "given an instance of MB::Component for scope" do
        let(:scope) { component }

        it "has a command type of :component" do
          subject.type.should eql(:component)
        end

        it "has a plugin matching the component's plugin" do
          subject.plugin.should eql(component.plugin)
        end
      end

      context "given an instance of MB::Plugin for scope" do
        let(:scope) { plugin }

        it "has a command type of :plugin" do
          subject.type.should eql(:plugin)
        end

        it "has a plugin matching the given scope" do
          subject.plugin.should eql(plugin)
        end
      end

      context "given an instance of an object that does not fit into a scope type" do
        let(:scope) { double }

        it "raises a RuntimeError" do
          expect {
            subject
          }.to raise_error(RuntimeError)
        end
      end
    end
  end

  subject { command }

  let(:command) do
    described_class.new("start", scope) do
      description "start all services"
      execute do; true; end
    end
  end

  let(:metadata) do
    double('metadata',
      name: "rspec-test",
      version: "1.2.3"
    )
  end

  let(:scope) { MB::Plugin.new(metadata) }

  its(:name) { should eql("start") }
  its(:description) { should eql("start all services") }
  its(:execute) { should be_a Proc }

  describe "#invoke" do
    pending
  end
end
