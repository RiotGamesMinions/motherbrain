require 'spec_helper'

describe MB::CommandInvoker::Worker do
  let(:component) { double('component', name: 'chat') }
  let(:command) { double('command', name: 'stop', type: :component, scope: component) }
  let(:environment) { "rspec-env" }

  subject { described_class.new(command, environment) }

  describe "#run" do
    let(:job) { double('job') }
    let(:arguments) { Array.new }

    before do
      job.stub(set_status: nil)
      command.stub(invoke: nil)
    end

    let(:run) { subject.run(job, arguments) }

    it "sets a status message" do
      job.should_receive(:set_status)

      run
    end

    it "invokes the command" do
      command.should_receive(:invoke).with(environment)

      run
    end

    context "when given additional arguments" do
      let(:arguments) { [1,2,3] }

      it "invokes the command with the additional arguments" do
        command.should_receive(:invoke).with(environment, *arguments)

        run
      end
    end
  end
end
