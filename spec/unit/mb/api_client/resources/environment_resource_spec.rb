require 'spec_helper'

describe MB::ApiClient::EnvironmentResource do
  subject { MB::ApiClient.new.environment }

  describe "#bootstrap" do
    let(:plugin_id) { "activemq" }
    let(:env_id) { "rspec-environment" }
    let(:manifest) { MB::Bootstrap::Manifest.new }

    it "sends a POST to /plugins/{plugin_id}/bootstrap.json with the necessary JSON body" do
      stub_request(:post, "http://0.0.0.0:1984/plugins/#{plugin_id}/bootstrap.json").
        with(body: MultiJson.encode(manifest: manifest, environment: env_id)).
        to_return(status: 200, body: MultiJson.encode({}))

      subject.bootstrap(env_id, plugin_id, manifest)
    end

    context "given a value for the :version option" do
      let(:version) { "1.0.0" }

      it "sends a POST to /plugins/{plugin_id}/{version}/bootstrap.json with the necessary JSON" do
        stub_request(:post, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0/bootstrap.json").
          with(body: MultiJson.encode(manifest: manifest, environment: env_id)).
          to_return(status: 200, body: MultiJson.encode({}))

        subject.bootstrap(env_id, plugin_id, manifest, version: version)
      end
    end
  end

  describe "#destroy" do
    let(:env_id) { "rspec-environment" }

    it "returns decoded JSON from /environments.json" do
      stub_request(:delete, "http://0.0.0.0:1984/environments/#{env_id}.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.destroy(env_id).should be_a(Hash)
    end
  end

  describe "#provision" do
    let(:plugin_id) { "activemq" }
    let(:env_id) { "rspec-environment" }
    let(:manifest) { MB::Provisioner::Manifest.new }

    it "sends a POST to /plugins/{plugin_id}/provision.json with the necessary JSON body" do
      stub_request(:post, "http://0.0.0.0:1984/plugins/#{plugin_id}/provision.json").
        with(body: MultiJson.encode(manifest: manifest, environment: env_id)).
        to_return(status: 200, body: MultiJson.encode({}))

      subject.provision(env_id, plugin_id, manifest)
    end

    context "given a value for the :version option" do
      let(:version) { "1.0.0" }

      it "sends a POST to /plugins/{plugin_id}/{version}/provision.json with the necessary JSON" do
        stub_request(:post, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0/provision.json").
          with(body: MultiJson.encode(manifest: manifest, environment: env_id)).
          to_return(status: 200, body: MultiJson.encode({}))

        subject.provision(env_id, plugin_id, manifest, version: version)
      end
    end
  end
end
