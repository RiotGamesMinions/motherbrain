require 'spec_helper'

describe MB::Cli::Base do
  describe "ClassMethods" do
    describe "::shell" do
      before do
        Chozo::Platform.stub(windows?: false, osx?: false, linux?: false)
      end

      subject { described_class.shell }
      after { described_class.shell = nil }

      context "when on a unix platform" do
        before do
          Chozo::Platform.stub(windows?: false, osx?: true, linux?: true)
        end

        it { should eql(MB::Cli::Shell::Color) }
      end

      context "when on a windows platform" do
        before do
          Chozo::Platform.stub(windows?: true, osx?: false, linux?: false)
        end

        it { should eql(MB::Cli::Shell::Basic) }
      end

      context "when the MB_SHELL env variable is set" do
        before do
          ENV.stub(:[]).with("MB_SHELL").and_return("basic")
        end

        it { should eql(MB::Cli::Shell::Basic) }
      end
    end
  end

  subject { described_class.new }

  describe "#display_job" do
    let(:job) { double('job') }

    it "creates a new CliClient with the given job and displays it" do
      cli_client = double('cli_client')
      MB::CliClient.should_receive(:new).with(job).and_return(cli_client)
      cli_client.should_receive(:display)

      subject.display_job(job)
    end
  end
end
