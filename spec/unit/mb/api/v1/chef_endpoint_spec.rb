require 'spec_helper'

describe MB::API::V1::ChefEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.app }
  let(:job) { MB::Job.new(:test) }

  describe "POST /chef/purge" do
    let(:hostname) { "foo.bar.com" }

    it "returns 201" do
      node_querier.should_receive(:async_purge).with(hostname, anything()).and_return(job.ticket)
      json_post "/chef/purge",
        MultiJson.dump(hostname: hostname)
      last_response.status.should == 201
    end
  end

  describe "POST /chef/upgrade" do
    let(:version) { "1.2.3" }
    let(:environment_id) { "rpsec_test" }
    let(:host) { "1.1.1.1" }

    context "when neither environment_id nor host are provided" do
      it "returns a 400" do
        json_post "/chef/upgrade",
          MultiJson.dump(version: version)

        last_response.status.should == 400
      end
    end

    context "when both environment_id and host are provided" do
      it "returns a 400" do
        json_post "/chef/upgrade",
          MultiJson.dump(version: version, environment_id: environment_id, host: host)

        last_response.status.should == 400
      end
    end

    context "when host is provided" do
      let(:node_object) { Ridley::NodeObject.new(host, automatic: { fqdn: host }) }

      it "returns 201" do
        node_querier.should_receive(:async_upgrade_omnibus).with(version, [node_object], anything()).and_return(job.ticket)

        json_post "/chef/upgrade",
          MultiJson.dump(version: version, host: host)

        last_response.status.should == 201
      end
    end
    
    context "when environment_id is provided" do
      let(:nodes) { ["node1", "node2", "node3"] }

      before do
        environment_manager.stub(:nodes_for_environment).and_return(nodes)
      end

      it "returns 201" do
        node_querier.should_receive(:async_upgrade_omnibus).with(version, nodes, anything()).and_return(job.ticket)

        json_post "/chef/upgrade",
          MultiJson.dump(version: version, environment_id: environment_id)

        last_response.status.should == 201
      end
    end
  end
end
