require 'spec_helper'

describe MB::Bootstrap::Manager do
  let(:plugin) do
    MB::Plugin.new do
      name "pvpnet"
      version "1.2.3"

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
  end

  let(:manifest) do
    MB::Bootstrap::Manifest.new(
      "activemq::master" => [
        "amq1.riotgames.com",
        "amq2.riotgames.com"
      ],
      "activemq::slave" => [
        "amqs1.riotgames.com",
        "amqs2.riotgames.com"
      ],
      "nginx::master" => [
        "nginx1.riotgames.com"
      ]
    )
  end

  let(:environment) { "test" }
  let(:server_url) { MB::Application.config.chef.api_url }

  subject { described_class.new }

  before(:each) do
    stub_request(:get, File.join(server_url, "nodes")).
      to_return(status: 200, body: {})
    stub_request(:get, File.join(server_url, "environments/test")).
      to_return(status: 200, body: {})
  end
end
