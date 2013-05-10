require 'spec_helper'

describe MB::CliClient do
  subject { cli_client }

  let(:cli_client) { MB::CliClient.new job }
  let(:job) { MB::Job.new :job_name }

  before do
    cli_client.stub printf: nil, puts: nil
  end

  describe "#print_statuses" do
    it "preserves ordering of the status buffer" do
      job.status = "1"

      cli_client.should_receive(:print_with_spinner).with("1").ordered

      cli_client.send(:print_statuses)

      job.status = "2"
      job.status = "3"

      cli_client.should_receive(:print_with_new_line).with("1").ordered
      cli_client.should_receive(:print_with_new_line).with("2").ordered
      cli_client.should_receive(:print_with_spinner).with("3").ordered

      cli_client.send(:print_statuses)

      job.status = "4"

      cli_client.should_receive(:print_with_new_line).with("3").ordered
      cli_client.should_receive(:print_with_spinner).with("4").ordered

      cli_client.send(:print_statuses)

      cli_client.should_receive(:print_with_spinner).with("4").ordered

      cli_client.send(:print_statuses)

      job.status = "5"
      job.status = "6"

      cli_client.should_receive(:print_with_new_line).with("4").ordered
      cli_client.should_receive(:print_with_new_line).with("5").ordered
      cli_client.should_receive(:print_with_spinner).with("6").ordered

      cli_client.send(:print_statuses)
    end
  end
end
