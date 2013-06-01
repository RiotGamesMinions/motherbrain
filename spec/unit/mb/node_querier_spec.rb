require 'spec_helper'

describe MB::NodeQuerier do
  subject { node_querier }

  let(:node_querier) { described_class.new }
  let(:host) { "192.168.1.1" }
  let(:response) { double('response', stderr: nil, stdout: nil, error?: nil) }

  describe "#list" do
    it "returns a list of nodes from the motherbrain's chef connection" do
      nodes = double
      MB::Application.ridley.stub_chain(:node, :all).and_return(nodes)

      subject.list.should eql(nodes)
    end
  end

  describe "#ruby_script" do
    subject(:result) { node_querier.send(:ruby_script, 'node_name', double('host')) }
    before { node_querier.stub_chain(:chef_connection, :node, :ruby_script).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the response of the successfully run script" do
        expect(result).to eql('success')
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteScriptError" do
        expect { result }.to raise_error(MB::RemoteScriptError)
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
    subject(:result) { node_querier.chef_run(host) }

    before { node_querier.stub_chain(:chef_connection, :node, :chef_run).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when hostname is nil" do
      let(:host) { nil }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end

    context "when hostname is blank" do
      let(:host) { "" }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
      end
    end
  end

  describe "#put_secret" do
    let(:options) { { secret: File.join(fixtures_path, "fake_key.pem") } }
    subject(:result) { node_querier.put_secret(host, options) }

    before { node_querier.stub_chain(:chef_connection, :node, :put_secret).and_return(response) }

    context "when there is no file at the secret path" do
      let(:options) { Hash.new }

      it { should be_nil }
    end

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it { should be_nil }
    end
  end

  describe "#execute_command" do
    let(:command) { "echo 'hello!'" }
    subject(:result) { node_querier.execute_command(host, command) }
    before { node_querier.stub_chain(:chef_connection, :node, :execute_command).and_return(response) }

    context "when the response is a success" do
      before { response.stub(stdout: 'success', error?: false) }

      it "returns the Ridley response" do
        expect(result).to eql(response)
      end
    end

    context "when the response is a failure" do
      before { response.stub(stderr: 'error_message', error?: true) }

      it "raises a RemoteCommandError" do
        expect { result }.to raise_error(MB::RemoteCommandError)
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
