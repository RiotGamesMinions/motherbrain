require 'spec_helper'

describe MB::Bootstrap::Worker do
  let(:node_querier) { double('node_querier') }
  let(:chef_connection) { double('chef_connection') }

  let(:address) { "cloud-1.riotgames.com" }
  let(:host) { described_class::Host.new(address) }

  let(:options) { Hash.new }

  let(:instance) { described_class.new }
  subject { instance }

  before { host.stub(node_name: nil) }

  describe "#run" do
    pending
  end

  describe "#full_bootstrap" do
    let(:chef_connection) { double('chef_connection') }
    let(:response) { Ridley::HostConnector::Response.new("cloud-1.riotgames.com", exit_code: 0) }

    before do
      subject.stub(chef_connection: chef_connection)
      chef_connection.stub_chain(:node, :bootstrap).and_return(response)
    end

    let(:result) { subject.full_bootstrap(host) }

    it "returns an Hash" do
      expect(result).to be_a(Hash)
    end

    it "has a :node_name key" do
      expect(result).to have_key(:node_name)
    end

    it "has a :hostname key" do
      expect(result).to have_key(:hostname)
    end

    it "has a :bootstrap_type key with the value :full" do
      expect(result).to have_key(:bootstrap_type)
      expect(result[:bootstrap_type]).to eql(:full)
    end

    it "has a :message key" do
      expect(result).to have_key(:message)
    end

    it "has a :status key" do
      expect(result).to have_key(:status)
    end

    context "when response is a failure" do
      before do
        response.exit_code = -1
        response.stderr = "OH NO AN ERROR"
      end

      it "sets the value of the :status key to :error" do
        expect(result[:status]).to eql(:error)
      end

      it "has the value of STDERR for :message" do
        expect(result[:message]).to eql(response.stderr)
      end
    end

    context "when response is a success" do
      before { response.exit_code = 0 }

      it "sets the value of the :status key to :ok" do
        expect(result[:status]).to eql(:ok)
      end

      it "has a blank value for :message" do
        expect(result[:message]).to be_blank
      end
    end
  end

  describe "#partial_bootstrap" do
    before { host.stub(node_name: "cloud-1") }

    before(:each) do
      subject.stub(node_querier: node_querier, chef_connection: chef_connection)
      node_querier.stub(put_secret: nil, chef_run: nil)
      chef_connection.stub_chain(:node, :merge_data)
    end

    let(:result) { subject.partial_bootstrap(host) }
    let(:options) { Hash.new }

    it "merges the given data with chef, puts the chef secret on the node, and then runs chef" do
      chef_connection.node.should_receive(:merge_data).with(host.node_name, options)
      node_querier.should_receive(:put_secret).with(host.hostname).ordered
      node_querier.should_receive(:chef_run).with(host.hostname, nil).ordered

      subject.partial_bootstrap(host)
    end

    it "returns a Hash" do
      expect(result).to be_a(Hash)
    end

    it "has a :node_name key" do
      expect(result).to have_key(:node_name)
    end

    it "has a :hostname key" do
      expect(result).to have_key(:hostname)
    end

    it "has a value of :partial for :bootstrap_type" do
      expect(result[:bootstrap_type]).to eql(:partial)
    end

    it "has a value of :ok for :status" do
      expect(result[:status]).to eql(:ok)
    end

    it "has a :message key" do
      expect(result).to have_key(:message)
    end

    context "when placing the secret file on the node fails" do
      let(:exception) { MB::RemoteFileCopyError.new("error in copy") }

      before { node_querier.should_receive(:put_secret).and_raise(exception) }

      it "sets the value of the :status key to :error" do
        expect(result[:status]).to eql(:error)
      end

      it "has the string representation of the raised exception for :message" do
        expect(result[:message]).to eql(exception.to_s)
      end
    end

    context "when running chef on the node fails" do
      let(:exception) { MB::RemoteCommandError.new("error in command") }

      before { node_querier.should_receive(:chef_run).and_raise(exception) }

      it "sets the value of the :status key to :error" do
        expect(result[:status]).to eql(:error)
      end

      it "has the string representation of the raised exception for :message" do
        expect(result[:message]).to eql(exception.to_s)
      end
    end

    context "when the node does not have a node object in the Chef server" do
      let(:node_resource) { double('node_resource') }
      let(:options) { { run_list: "some_list", attributes: "some_attrs" } }
      before do
        chef_connection.stub(node: node_resource)
        node_resource.should_receive(:merge_data).and_raise(Ridley::Errors::ResourceNotFound)
      end

      it "sets the response to error" do
        expect(result[:status]).to eq(:error)
      end
    end
  end
end

describe MB::Bootstrap::Worker::Host do
  let(:address) { "reset.riotgames.com" }
  subject { described_class.new(address) }

  its(:hostname) { should eql(address) }

  context "when the host is registered to Chef" do
    before { MB::NodeQuerier.instance.stub(:registered_as).with(address).and_return(nil) }

    its(:node_name) { should be_nil }
    its(:partial_bootstrap?) { should be_false }
    its(:full_bootstrap?) { should be_true }
  end

  context "when the host is not registered with Chef" do
    let(:node_name) { "reset" }
    before { MB::NodeQuerier.instance.stub(:registered_as).with(address).and_return(node_name) }

    its(:node_name) { should eql(node_name) }
    its(:partial_bootstrap?) { should be_true }
    its(:full_bootstrap?) { should be_false }
  end
end
