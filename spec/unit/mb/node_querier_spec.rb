require 'spec_helper'

describe MB::NodeQuerier do
  subject { described_class.new }

  describe "#list" do
    it "returns a list of nodes from the motherbrain's chef connection" do
      nodes = double
      MB::Application.ridley.stub_chain(:node, :all).and_return(nodes)

      subject.list.should eql(nodes)
    end
  end

  describe "#ruby_script" do
    it "raises a RemoteScriptError if there was an error executing the script" do
      Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)      
      Ridley::HostConnector::SSH.stub(:ruby_script).and_return([:error, double('response', stderr: 'error_message')])

      expect {
        subject.ruby_script('node_name', double('host'))
      }.to raise_error(MB::RemoteScriptError, 'error_message')
    end
  end

  describe "#node_name" do
    it "returns the response of the successfully run script" do
      Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)      
      Ridley::HostConnector::SSH.stub(:ruby_script).and_return([:ok, double('response', stdout: 'my_node')])

      subject.node_name(double('host')).should eql('my_node')
    end

    it "returns nil if there was an error in remote execution" do
      Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)      
      Ridley::HostConnector::SSH.stub(:ruby_script).and_return([:error, double('response', stderr: 'error_message')])

      subject.node_name(double('host')).should be_nil
    end
  end

  describe "#write_file" do
    it "writes a temporary file and sends it to copy_file" do
      host    = double('host')
      options = double('opts')
      subject.should_receive(:copy_file).with(kind_of(String), '/tmp/file', host, options)

      subject.write_file('asdf', '/tmp/file', host, options)
    end
  end

  describe "#chef_run" do
    it "raises a RemoteCommandError if given a nil hostname" do
      expect {
        subject.chef_run(nil)
      }.to raise_error(MB::RemoteCommandError)
    end

    it "raises a RemoteCommandError if given a blank hostname" do
      expect {
        subject.chef_run("")
      }.to raise_error(MB::RemoteCommandError)
    end
  end

  describe "#put_secret" do
    let(:host) { "192.168.1.1" }
    let(:options) do 
      {
        secret: File.join(fixtures_path, "fake_key.pem")
      }
    end

    it "returns nil when there is no file at the secret path" do
      subject.put_secret(nil, {}).should be_nil
    end

    it "returns a Ridley::HostConnector::Response after a successful execution" do
      Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)
      Ridley::HostConnector::SSH.stub(:put_secret).and_return([:ok, Ridley::HostConnector::Response.new(host)])

      subject.put_secret(host, options).should be_a(Ridley::HostConnector::Response)
    end

    it "returns nil after an error" do
      Ridley::HostConnector.stub(:best_connector_for).and_yield(Ridley::HostConnector::SSH)      
      Ridley::HostConnector::SSH.stub(:put_secret).and_return([:error, Ridley::HostConnector::Response.new(host)])
     
      subject.put_secret(host, options).should be_nil
    end
  end

  describe "#registered?" do
    let(:host) { "192.168.1.1" }
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
    let(:host) { "192.168.1.1" }
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
