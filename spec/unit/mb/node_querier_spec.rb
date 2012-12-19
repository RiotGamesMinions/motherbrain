require 'spec_helper'

describe MB::NodeQuerier do
  subject { described_class.new }

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
      subject.should_receive(:ruby_script).and_return('my_node')

      subject.node_name(double('host')).should eql('my_node')
    end

    it "returns nil if there was an error in remote execution" do
      subject.should_receive(:ruby_script).and_raise(MB::RemoteScriptError)

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
end
