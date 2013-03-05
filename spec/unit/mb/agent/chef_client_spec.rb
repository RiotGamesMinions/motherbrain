require 'spec_helper'

describe MB::Agent::ChefClient do
  let(:options) { double('options') }

  subject { described_class.new }

  describe "#run" do
    let(:client) { double('chef-client') }
    let(:job) { double('job') }

    it "sets up a new client, registers a job notifier, and runs the client" do
      ::Chef::Client.should_receive(:new).with(nil, options).and_return(client)
      client.stub_chain(:events, :register).with(kind_of(MB::Agent::JobNotifier))
      client.should_receive(:run).and_return(:ok)

      subject.run(job, nil, options).should eql(:ok)
    end
  end
end
