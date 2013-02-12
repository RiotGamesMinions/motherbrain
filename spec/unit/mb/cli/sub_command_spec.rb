require 'spec_helper'

describe MB::Cli::SubCommand do
  subject { described_class }

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
        klass = subject.new(plugin)
        klass.should be_a(Class)
        klass.superclass.should eql(MB::Cli::SubCommand::Plugin)
      end
    end

    context "given a MB::Component" do
      let(:plugin) { double('plugin') }
      let(:component) { MB::Component.new(plugin) }

      it "returns an anonymous class whose superclass is MB::Cli::SubCommand::Component" do
        klass = subject.new(component)

        klass.should be_a(Class)
        klass.superclass.should eql(MB::Cli::SubCommand::Component)
      end
    end

    context "given a class which is not a MB::Plugin or MB::Component" do
      it "raises an ArgumentError" do
        expect {
          subject.new(double('whatever'))
        }.to raise_error(ArgumentError, "don't know how to fabricate a subcommand for a 'RSpec::Mocks::Mock'")
      end
    end
  end
end
