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

  describe "#bootstrap" do
    subject(:bootstrap) { manager.bootstrap(environment, manifest, plugin) }

    it "calls #start" do
      manager.should_receive(:start)

      bootstrap
    end
  end

  describe "#start" do
    subject(:start) { manager.start(environment, manifest, plugin, job_stub) }

    it "kicks off a sequential bootstrap" do
      job_stub.should_receive(:report_running)
      manager.should_receive(:sequential_bootstrap)

      start
    end
  end
end
