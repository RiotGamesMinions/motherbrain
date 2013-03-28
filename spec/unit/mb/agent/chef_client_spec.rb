require 'spec_helper'

describe MB::Agent::ChefClient do
  let(:options) { double('options') }

  subject { described_class.new }

  describe "#run" do
    let(:client) { double('chef-client') }
    let(:job) { double('job') }

    before(:each) do
      ::Chef::Client.stub(:new).and_return(client)
      client.stub(:run)
      client.stub_chain(:events, :register).with(kind_of(MB::Agent::JobNotifier))
    end

    it "passes the chef_attributes and options to the instantiated chef client" do
      ::Chef::Client.should_receive(:new).with(nil, options).and_return(client)

      subject.run(job, nil, options)
    end

    it "returns the result from the instantiated chef client's run" do
      client.should_receive(:run).and_return(:ok)

      subject.run(job, nil, options).should eql(:ok)
    end

    context "when the wrapped Chef client raises an exception" do
      it "re-raises as a ChefClientError" do
        client.should_receive(:run).and_raise(ArgumentError)

        expect {
          subject.run(job)
        }.to raise_error(MB::ChefClientError)
      end
    end
  end
end
