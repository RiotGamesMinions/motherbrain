require 'spec_helper'

describe MB::Bootstrap::Manager do
  subject { manager }
  let(:manager) { described_class.new }

  let(:cookbook_metadata) {
    MB::CookbookMetadata.from_file(fixtures_path.join('cb_metadata.rb'))
  }

  let(:plugin) {
    MB::Plugin.new(cookbook_metadata) do
      component "activemq" do
        group "master"
        group "slave"
      end

      component "nginx" do
        group "master"
      end

      cluster_bootstrap do
        async do
          bootstrap("activemq::master")
          bootstrap("activemq::slave")
        end

        bootstrap("nginx::master")
      end
    end
  }

  let(:manifest) {
    MB::Bootstrap::Manifest.new({
      nodes: [
        {
          groups: ["activemq::master"],
          hosts: [
            "amq1.riotgames.com",
            "amq2.riotgames.com"
          ]
        },
        {
          groups: ["activemq::slave"],
          hosts: [
            "amqs1.riotgames.com",
            "amqs2.riotgames.com"
          ]
        },
        {
          groups: ["nginx::master"],
          hosts: [
            "nginx1.riotgames.com"
          ]
        }
      ]
    })
  }

  let(:environment) { "test" }
  let(:server_url) { MB::Application.config.chef.api_url }
  let(:job_stub) { stub(MB::Job) }

  before do
    stub_request(:get, File.join(server_url, "nodes")).
      to_return(status: 200, body: {})
    stub_request(:get, File.join(server_url, "environments/test")).
      to_return(status: 200, body: {})

    manager.stub(async: manager)
  end

  describe "#async_bootstrap" do
    it "delegates asynchronously to {#bootstrap}" do
      options = double('options')
      manager.should_receive(:async).with(
        :bootstrap,
        kind_of(MB::Job),
        environment,
        manifest,
        plugin,
        options
      )

      manager.async_bootstrap(environment, manifest, plugin, options)
    end

    it "returns a JobRecord" do
      manager.async_bootstrap(environment, manifest, plugin).should be_a(MB::JobRecord)
    end
  end

  describe "#bootstrap" do
    before(:each) do
      job_stub.stub(:set_status)
      job_stub.should_receive(:report_running)
    end

    context "when the environment cannot be found" do
      before(:each) do
        manager.stub_chain(:chef_connection, :environment, :find).with(environment).and_return(nil)
      end

      it "sets the job to failed and terminates it" do
        job_stub.should_receive(:report_failure)
        job_stub.should_receive(:alive?) { true }
        job_stub.should_receive(:terminate)
        
        manager.bootstrap(job_stub, environment, manifest, plugin)
      end
    end
  end

  describe "#concurrent_bootstrap" do
    pending
  end
end
