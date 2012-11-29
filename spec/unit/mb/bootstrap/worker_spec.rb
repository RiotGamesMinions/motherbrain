require 'spec_helper'

describe MB::Bootstrap::Worker do
  let(:chef_conn) { double('chef_conn') }
  let(:group_id) { "rspec::test_recipe" }

  let(:nodes) do
    [
      "one.riotgames.com",
      "two.riotgames.com"
    ]
  end

  let(:options) do
    {
      run_list: [
        "nginx::source"
      ],
      attributes: {
        nginx: "master"
      }
    }
  end

  subject { described_class.new(chef_conn, group_id, nodes, options) }

  describe "#run" do
    pending
  end

  describe "#bootstrap_type_filter" do
    before(:each) do
      chef_conn.stub_chain(:client, :all).and_return([])
    end

    it "returns an array of two elements" do
      result = subject.bootstrap_type_filter

      result.should be_a(Array)
      result.should have(2).items
    end

    it "has an array of nodes which do not have a client at index 0" do
      client_1 = double('client_1', name: nodes[0])
      chef_conn.stub_chain(:client, :all).and_return([client_1])
      result = subject.bootstrap_type_filter

      result[0].should be_a(Array)
      result[0].should have(1).item
      result[0].should eql([nodes[1]])
    end

    it "has an array of nodes which do have a client at index 1" do
      client_1 = double('client_1', name: nodes[0])
      chef_conn.stub_chain(:client, :all).and_return([client_1])
      result = subject.bootstrap_type_filter

      result[1].should be_a(Array)
      result[1].should have(1).item
      result[1].should eql([nodes[0]])
    end
  end
end
