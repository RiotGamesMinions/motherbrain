require 'spec_helper'

describe MB::Cli::Base do
  subject { cli }

  let(:cli) { described_class.new }

  describe "#display_job" do
    let(:job) { double('job') }

    it "creates a new CliClient with the given job and displays it" do
      cli_client = double('cli_client')
      MB::CliClient.should_receive(:new).with(job).and_return(cli_client)
      cli_client.should_receive(:display)

      subject.display_job(job)
    end
  end

  describe "#requires_one_of" do
    let(:options) { Hash.new }
    let(:ui_stub) { double }

    before do
      cli.stub options: options, ui: ui_stub
    end

    it "exits with an error message" do
      ui_stub.should_receive(:say)
      cli.should_receive(:exit)

      cli.requires_one_of(:a, :b)
    end

    context "with at least one valid option" do
      let(:options) { { a: 1 } }

      it "does not exit" do
        cli.requires_one_of(:a, :b)
      end
    end
  end
end
