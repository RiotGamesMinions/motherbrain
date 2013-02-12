require 'spec_helper'

describe MB::Cli::SubCommand do
  subject { described_class }
  let(:environment) { "test_environment" }

  describe "::new" do
    context "given a MB::Plugin" do
      let(:metadata) do
        double('metadata',
          valid?: true,
          name: "rspec-test"
        )
      end

      let(:plugin) { MB::Plugin.new(metadata) }

      it "returns an anonymous class whose superclass is MB::Cli::SubCommand::Plugin" do
        klass = subject.new(plugin, environment)
        klass.should be_a(Class)
        klass.superclass.should eql(MB::Cli::SubCommand::Plugin)
      end
    end

    context "given a MB::Component" do
      let(:plugin) { double('plugin') }
      let(:component) { MB::Component.new(plugin) }

      it "returns an anonymous class whose superclass is MB::Cli::SubCommand::Component" do
        klass = subject.new(component, environment)

        klass.should be_a(Class)
        klass.superclass.should eql(MB::Cli::SubCommand::Component)
      end
    end

    context "given a class which is not a MB::Plugin or MB::Component" do
      it "raises an ArgumentError" do
        expect {
          subject.new(double('whatever'), environment)
        }.to raise_error(ArgumentError, "don't know how to fabricate a subcommand for a 'RSpec::Mocks::Mock'")
      end
    end
  end
end
