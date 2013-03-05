require 'spec_helper'

describe MB::Agent::ChefClient do
  subject { described_class.new }

  describe "#run" do
    let(:client) { double('chef-client') }

    it "delegates to client#run" do
      subject.stub(:client) { client }
      client.should_receive(:run)

      subject.run
    end
  end
end
