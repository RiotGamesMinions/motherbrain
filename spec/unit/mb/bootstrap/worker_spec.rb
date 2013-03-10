require 'spec_helper'

describe MB::Bootstrap::Worker do
  let(:nodes) do
    [
      "cloud-1.riotgames.com",
      "cloud-2.riotgames.com"
    ]
  end

  let(:options) { Hash.new }

  subject do
    described_class.new(nodes)
  end

  describe "#run" do
    pending
  end

  describe "#bootstrap_type_filter" do
    pending
  end

  describe "#nodes" do
    pending
  end

  describe "#_full_bootstrap_" do
    pending
  end

  describe "#partial_bootstrap" do
    let(:node) do
      {
        node_name: "cloud-1",
        hostname: "cloud-1.riotgames.com"
      }
    end

    let(:nodes) { [node] }

    before(:each) do
      subject.chef_connection.stub_chain(:node, :merge_data).with(node[:node_name], options)
      subject.node_querier.should_receive(:put_secret).with(node[:hostname])
      subject.node_querier.should_receive(:chef_run).with(node[:hostname])
    end

    it "returns an array of hashes" do
      subject.partial_bootstrap(nodes).should each be_a(Hash)
    end

    it "each hash has a ':node_name' key/value" do
      subject.partial_bootstrap(nodes).should each have_key(:node_name)
    end

    it "each hash has a ':hostname' key/value" do
      subject.partial_bootstrap(nodes).should each have_key(:hostname)
    end

    it "each hash has a value of ':partial' for ':bootstrap_type'" do
      response = subject.partial_bootstrap(nodes)

      response.should each have_key(:bootstrap_type)
      response.each do |result|
        result[:bootstrap_type].should eql(:partial)
      end
    end

    it "each hash has a value of ':ok' for ':status'" do
      response = subject.partial_bootstrap(nodes)

      response.should each have_key(:status)
      response.each do |result|
        result[:status].should eql(:ok)
      end
    end

    it "each hash has a ':message' key/value" do
      subject.partial_bootstrap(nodes).should each have_key(:message)
    end
  end
end
