require 'spec_helper'

describe MB::Bootstrap::Worker do
  let(:node_querier) { double('node_querier') }
  let(:chef_connection) { double('chef_connection') }

  let(:nodes) do
    [
      "cloud-1.riotgames.com",
      "cloud-2.riotgames.com"
    ]
  end

  let(:options) { Hash.new }

  let(:instance) { described_class.new }
  subject { instance }

  describe "#run" do
    context "when there are no nodes" do
      let(:nodes) { Array.new }

      it "returns an empty array" do
        result = subject.run(nodes)

        result.should be_a(Array)
        result.should be_empty
      end
    end
  end

  describe "#expand_hosts" do
    let(:hosts) do
      [
        "cloud-1.riotgames.com",
        "cloud-2.riotgames.com"
      ]
    end

    before do
      instance.stub(node_querier: node_querier)
      node_querier.stub(:registered_as, anything) { |arg| arg }
    end

    subject { instance.expand_hosts(hosts) }

    it "returns an array of Hashes" do
      expect(subject).to be_a(Array)
      expect(subject).to each be_a(Hash)
    end

    it "each contains a :hostname key" do
      expect(subject).to each have_key(:hostname)
    end

    it "each contains a :node_name key" do
      expect(subject).to each have_key(:node_name)
    end

    context "hosts that are registered to the Chef server" do
      let(:node_names) do
        {
          "cloud-1.riotgames.com" => "cloud-1",
          "cloud-2.riotgames.com" => "cloud-2"
        }
      end

      before do
        node_names.each do |host, name|
          node_querier.should_receive(:registered_as).with(host).and_return(name)
        end
      end

      it "has a value for node_name matching the name the node is registered_as to Chef" do
        expect(subject).to have(2).items
        expect(subject[0][:node_name]).to eql("cloud-1")
        expect(subject[1][:node_name]).to eql("cloud-2")
      end
    end

    context "hosts that are not registered to the Chef server" do
      let(:node_names) do
        {
          "cloud-1.riotgames.com" => nil,
          "cloud-2.riotgames.com" => nil
        }
      end

      before do
        node_names.each do |host, name|
          node_querier.should_receive(:registered_as).with(host).and_return(name)
        end
      end

      it "has a nil value for node_name" do
        expect(subject).to have(2).items
        expect(subject[0][:node_name]).to be_nil
        expect(subject[1][:node_name]).to be_nil
      end
    end
  end

  describe "#full_bootstrap" do
    let(:chef_connection) { double('chef_connection') }
    let(:hosts) do
      hostnames = [
        "cloud-1.riotgames.com",
        "cloud-2.riotgames.com"
      ]
    end

    let(:response_1) { Ridley::HostConnector::Response.new("cloud-1.riotgames.com", exit_code: 0) }
    let(:response_set) { Ridley::HostConnector::ResponseSet.new([response_1])}

    before do
      subject.stub(chef_connection: chef_connection)
      chef_connection.stub_chain(:node, :bootstrap).and_return(response_set)
    end

    it "returns an array of Hashes" do
      result = subject.full_bootstrap(hosts)

      result.should be_a(Array)
      result.should each be_a(Hash)
    end

    context "each response" do
      let(:response) { subject.full_bootstrap(hosts).first }

      it "has a :node_name key" do
        response.should have_key(:node_name)
      end

      it "has a :hostname key" do
        response.should have_key(:hostname)
      end

      it "has a :bootstrap_type key with the value :full" do
        response.should have_key(:bootstrap_type)
        response[:bootstrap_type].should eql(:full)
      end

      it "has a :message key" do
        response.should have_key(:message)
      end

      it "has a :status key" do
        response.should have_key(:status)
      end

      context "when response is a failure" do
        before do
          response_1.exit_code = -1
          response_1.stderr = "OH NO AN ERROR"
        end

        it "sets the value of the :status key to :error" do
          response[:status] == :error
        end

        it "has the value of STDERR for :message" do
          response[:message].should eql(response_1.stderr)
        end
      end

      context "when response is a success" do
        before { response_1.exit_code = 0 }

        it "sets the value of the :status key to :ok" do
          response[:status] == :ok
        end

        it "has a blank value for :message" do
          response[:message].should be_blank
        end
      end
    end
  end

  describe "#partial_bootstrap" do
    let(:node) do
      {
        node_name: "cloud-1",
        hostname: "cloud-1.riotgames.com"
      }
    end

    let(:nodes) { [ node ] }

    before(:each) do
      subject.stub(node_querier: node_querier, chef_connection: chef_connection)
      node_querier.stub(put_secret: nil, chef_run: nil)
      chef_connection.stub_chain(:node, :merge_data)
    end

    it "merges the given data with chef, puts the chef secret on the node, and then runs chef" do
      chef_connection.node.should_receive(:merge_data).with(node[:node_name], options)
      node_querier.should_receive(:put_secret).with(node[:hostname]).ordered
      node_querier.should_receive(:chef_run).with(node[:hostname]).ordered

      subject.partial_bootstrap(nodes)
    end

    it "returns an array of hashes" do
      subject.partial_bootstrap(nodes).should each be_a(Hash)
    end

    context "each response" do
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

      context "when placing the secret file on the node fails" do
        let(:exception) { MB::RemoteFileCopyError.new("error in copy") }
        let(:response) { subject.partial_bootstrap(nodes).first }

        before do
          node_querier.should_receive(:put_secret).and_raise(exception)
        end

        it "sets the value of the :status key to :error" do
          response[:status] == :error
        end

        it "has the string representation of the raised exception for :message" do
          response[:message].should eql(exception.to_s)
        end
      end

      context "when running chef on the node fails" do
        let(:exception) { MB::RemoteCommandError.new("error in command") }
        let(:response) { subject.partial_bootstrap(nodes).first }

        before do
          node_querier.should_receive(:chef_run).and_raise(exception)
        end

        it "sets the value of the :status key to :error" do
          response[:status] == :error
        end

        it "has the string representation of the raised exception for :message" do
          response[:message].should eql(exception.to_s)
        end
      end

      context "when the node does not have a node object in the Chef server" do
        let(:node_resource) { double('node_resource') }
        before do
          chef_connection.stub(node: node_resource)
          node_resource.should_receive(:merge_data).and_raise(Ridley::Errors::ResourceNotFound)
        end

        it "sets the response to error" do
          data = { run_list: "some_list", attributes: "some_attrs" }

          response = subject.partial_bootstrap(nodes, data).first
          expect(response[:status]).to eq(:error)
        end
      end
    end
  end
end
