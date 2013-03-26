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
      subject.stub(:ssh_command).and_return([:error, double('response', stderr: 'error_message')])

      expect {
        subject.ruby_script('node_name', double('host'))
      }.to raise_error(MB::RemoteScriptError, 'error_message')
    end
  end

  describe "#node_name" do
    it "returns the response of the successfully run script" do
      subject.should_receive(:_ruby_script_).and_return('my_node')

      subject.node_name(double('host')).should eql('my_node')
    end

    it "returns nil if there was an error in remote execution" do
      subject.should_receive(:_ruby_script_).and_raise(MB::RemoteScriptError)

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

  describe "#registered?" do
    let(:host) { "192.168.1.1" }
    let(:node_name) { "reset.riotgames.com" }

    before do
      subject.stub(:node_name).with(host).and_return(node_name)
    end

    it "returns true if the target node has a client registered on the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(double)

      subject.registered?(host).should be_true
    end

    it "returns false if the target node does not have a client registered on the Chef server" do
      subject.chef_connection.stub_chain(:client, :find).with(node_name).and_return(nil)

      subject.registered?(host).should be_false
    end

    context "when the target node's node_name cannot be resolved" do
      before do
        subject.stub(:node_name).with(host).and_return(nil)
      end

      it "returns false" do
        subject.registered?(host).should be_false
      end
    end
  end
end
