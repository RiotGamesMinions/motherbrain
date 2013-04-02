require 'spec_helper'

describe MB::Cli::Base do
  subject { described_class.new }

  describe "#display_job" do
    let(:job) { double('job') }

    it "creates a new CliClient with the given job and displays it" do
      cli_client = double('clie_client')
      MB::CliClient.should_receive(:new).with(job).and_return(cli_client)
      cli_client.should_receive(:display)

      subject.display_job(job)
    end
  end
end
