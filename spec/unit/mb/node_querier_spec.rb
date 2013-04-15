require 'spec_helper'

describe MB::NodeQuerier do
  subject { node_querier }

  let(:node_querier) { described_class.new }
  let(:host) { "192.168.1.1" }

  describe "#list" do
    it "returns a list of nodes from the motherbrain's chef connection" do
      nodes = double
      MB::Application.ridley.stub_chain(:node, :all).and_return(nodes)

      subject.list.should eql(nodes)
    end
  end

  describe "#ruby_script" do
    subject { ruby_script }

    let(:response) { [ :ok, double('response', stdout: 'my_node') ] }
    let(:ruby_script) { node_querier.send(:ruby_script, 'node_name', double('host')) }

    before do
      node_querier.stub_chain(:chef_connection, :node, :ruby_script).and_return(response)
    end

    it "returns the response of the successfully run script" do
      ruby_script.should eq('my_node')
    end

    context "when an error occurs" do
      let(:response) { [:error, double('response', stderr: 'error_message')] }

      it "raises a RemoteScriptError" do
        expect {
          ruby_script
        }.to raise_error(MB::RemoteScriptError)
      end
    end

    context "when ridley returns an unknown status" do
      let(:response) { [ :unknown, double ] }

      it "rasies a RuntimeError" do
        expect {
          ruby_script
        }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#node_name" do
    subject(:node_name) { node_querier.node_name(host) }

    let(:node) { "my_node" }

    it "calls ruby_script with node_name and returns a response" do
      node_querier.should_receive(:ruby_script).with('node_name', host, {}).and_return(node)
      node_name.should eq(node)
    end

    context "with a remote script error" do
      before do
        node_querier.stub(:ruby_script).and_raise(MB::RemoteScriptError)
      end

      it { should be_nil }
    end
  end

  describe "#chef_run" do
    subject { chef_run }

    let(:chef_run) { node_querier.chef_run(host) }
    let(:response) { [:ok, Ridley::HostConnector::Response.new(host)] }

    before do
      node_querier.stub_chain(:chef_connection, :node, :chef_run).and_return(response)
    end

    it { should be_a(Ridley::HostConnector::Response) }

    context "when hostname is nil" do
      let(:host) { nil }

      it "raises a RemoteCommandError" do
        expect {
          chef_run
        }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when hostname is blank" do
      let(:host) { "" }

      it "raises a RemoteCommandError" do
        expect {
          chef_run
        }.to raise_error(MB::RemoteCommandError)
      end
    end
  end

  describe "#put_secret" do
    subject { put_secret }

    let(:put_secret) { node_querier.put_secret(host, options) }
    let(:options) do
      {
        secret: File.join(fixtures_path, "fake_key.pem")
      }
    end
    let(:response) { [:ok, Ridley::HostConnector::Response.new(host)] }

    before do
      node_querier.stub_chain(:chef_connection, :node, :put_secret).and_return(response)
    end

    it { should be_a(Ridley::HostConnector::Response) }

    context "when there is no file at the secret path" do
      let(:options) { {} }

      it { should be_nil }
    end

    context "when an error occurs" do
      let(:response) { [:error, Ridley::HostConnector::Response.new(host)] }

      it { should be_nil }
    end
  end

  describe "#execute_command" do
    subject { execute_command }

    let(:execute_command) { node_querier.execute_command(host, command) }
    let(:command) { "echo 'hello!'" }
    let(:response) { [:ok, Ridley::HostConnector::Response.new(host)] }

    before do
      node_querier.stub_chain(:chef_connection, :node, :execute_command).and_return(response)
    end

    it { should be_a(Ridley::HostConnector::Response) }

    context "when an error occurs" do
      let(:response) { [:error, double('error', stderr: 'error_message')] }

      it "aborts a RemoteCommandError" do
        node_querier.should_receive(:abort).with(MB::RemoteCommandError.new(response[1].stderr))
        execute_command
      end
    end
  end

  describe "#registered?" do
    let(:node_name) { "reset.riotgames.com" }

    it "returns true if the target node is registered with the Chef server" do
      subject.should_receive(:registered_as).with(host).and_return(node_name)

      subject.registered?(host).should be_true
    end

    it "returns false if the target node is not registered with the Chef server" do
      subject.should_receive(:registered_as).with(host).and_return(nil)

      subject.registered?(host).should be_false
    end
  end

  describe "#registered_as" do
    let(:node_name) { "reset.riotgames.com" }
    let(:client) { double('client', name: node_name) }

    before do
      subject.stub(:node_name).with(host).and_return(node_name)
    end

    it "returns the name of the client the target node has registered to the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(client)

      subject.registered_as(host).should eql(client.name)
    end

    it "returns nil if the target node does not have a client registered on the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(nil)

      subject.registered_as(host).should be_nil
    end

    it "returns nil if we can't determine the node_name of the host" do
      subject.should_receive(:node_name).with(host).and_return(nil)

      subject.registered_as(host).should be_nil
    end

    context "when the target node's node_name cannot be resolved" do
      before do
        subject.stub(:node_name).with(host).and_return(nil)
      end

      it "returns false" do
        subject.registered_as(host).should be_false
      end
    end
  end
end
