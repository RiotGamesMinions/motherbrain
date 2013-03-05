require 'spec_helper'

describe MB::Agent do
  subject { described_class }

  describe "::setup" do
    let(:supervision_group) { MB::Agent::SupervisionGroup }
    let(:options) { Hash.new }

    before(:each) { subject.setup(options) }

    context "given no options" do
      it "sets the supervision group's chef_options to an empty Hash" do
        supervision_group.chef_options.should be_a(Hash)
        supervision_group.chef_options.should be_empty
      end

      it "sets the supervision group's ohai_options to an empty Hash" do
        supervision_group.ohai_options.should be_a(Hash)
        supervision_group.ohai_options.should be_empty
      end
    end

    context "given a hash containing a key :chef_options" do
      let(:options) do
        { chef_options: "some chef options!" }
      end

      it "sets the supervision group's chef_options to the value" do
        supervision_group.chef_options.should eql(options[:chef_options])
      end
    end

    context "given a hash containing a key :ohai_options" do
      let(:options) do
        { ohai_options: "some ohai options!" }
      end

      it "sets the supervision group's chef_options to the value" do
        supervision_group.ohai_options.should eql(options[:ohai_options])
      end
    end

    context "given a hash containing a key :node_id" do
      let(:options) do
        { node_id: "reset.riotgames.com" }
      end

      it "sets the node_id to the value" do
        subject.node_id.should eql(options[:node_id])
      end
    end

    context "given a hash containing a key :host" do
      let(:options) do
        { host: "192.168.1.1" }
      end

      it "sets the host to the value" do
        subject.host.should eql(options[:host])
      end
    end

    context "given a hash containing a key :port" do
      let(:options) do
        { port: 2013 }
      end

      it "sets the port to the value" do
        subject.port.should eql(options[:port])
      end
    end
  end
end
