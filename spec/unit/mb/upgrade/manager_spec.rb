require 'spec_helper'

describe MB::Upgrade::Manager do
  let(:environment) { "environment" }
  let(:plugin) { double('plugin') }
  let(:options) { Hash.new }

  subject { described_class.new }

  describe "#async_upgrade" do
    let(:ticket) { double('ticket') }
    let(:job) { double('job', ticket: ticket) }

    before(:each) do
      MB::Job.should_receive(:new).with(:upgrade).and_return(job)
      subject.should_receive(:async).with(:upgrade, job, environment, plugin, options).and_return(ticket)
    end

    it "returns a job ticket" do
      subject.async_upgrade(environment, plugin, options).should eql(ticket)
    end
  end

  describe "#upgrade" do
    let(:job) { double('job', alive?: true) }
    let(:worker) { double('worker', alive?: true) }

    it "runs the request in a worker and then terminates the job and worker" do
      MB::Upgrade::Worker.should_receive(:new).with(job, environment, plugin, options).and_return(worker)
      job.should_receive(:terminate)
      worker.should_receive(:terminate)
      worker.should_receive(:run)

      subject.upgrade(job, environment, plugin, options)
    end
  end
end
