require 'spec_helper'

describe MB::Upgrade::Manager do
  let(:environment) { "environment" }
  let(:plugin) do
    metadata = MB::CookbookMetadata.new do
      name "motherbrain"
      version "0.1.0"
    end
    MB::Plugin.new(metadata)
  end
  let(:options) { Hash.new }

  let(:worker_stub) { stub MB::Upgrade::Worker }

  describe "#upgrade" do
    let(:ticket) { double('ticket') }
    let(:job) { double('job', ticket: ticket) }
    let(:upgrade) { klass.new.upgrade environment, plugin, options }

    it "creates a job and delegates to a worker" do
      future = double
      MB::Job.should_receive(:new).with(:upgrade).and_return(job)
      MB::Upgrade::Worker.should_receive(:new).with(environment, plugin, job, options).and_return(worker_stub)
      worker_stub.stub(:async).and_return(future)
      future.should_receive(:run)

      upgrade
    end
  end
end
