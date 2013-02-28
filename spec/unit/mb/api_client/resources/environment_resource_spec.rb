require 'spec_helper'

describe MB::ApiClient::EnvironmentResource do
  subject { MB::ApiClient.new.environment }

  let(:empty_response) { MultiJson.encode({}) }

  describe "#bootstrap" do
    let(:plugin_id) { "activemq" }
    let(:env_id) { "rspec-environment" }
    let(:manifest) { MB::Bootstrap::Manifest.new }

    it "sends a PUT to /environments/{id}.json" do
      req_body = MultiJson.encode(
        manifest: manifest,
        plugin: {
          name: plugin_id,
          version: nil
        },
        force: nil,
        hints: nil
      )

      stub_request(:put, "http://0.0.0.0:1984/environments/#{env_id}.json").
        with(body: req_body).
        to_return(status: 200, body: empty_response)

      subject.bootstrap(env_id, plugin_id, manifest)
    end
  end

  describe "#configure" do
    let(:env_id) { "rspec-environment" }
    let(:attributes) do
      {
        key_one: "value_one"
      }
    end
    let(:force) { false }

    it "sends a POST to /environments/{id}/configure.json" do
      req_body = MultiJson.encode(
        attributes: attributes,
        force: force
      )

      stub_request(:post, "http://0.0.0.0:1984/environments/#{env_id}/configure.json").
        with(body: req_body).
        to_return(status: 200, body: empty_response)

      subject.configure(env_id, attributes: attributes, force: false)
    end
  end

  describe "#destroy" do
    let(:env_id) { "rspec-environment" }

    it "sends a DELETE to /environments/{id}.json" do
      stub_request(:delete, "http://0.0.0.0:1984/environments/#{env_id}.json").
        to_return(status: 200, body: empty_response)

      subject.destroy(env_id).should be_a(Hash)
    end
  end

  describe "#list" do
    it "sends a GET to /environments.json" do
      stub_request(:get, "http://0.0.0.0:1984/environments.json").
        to_return(status: 200, body: empty_response)

      subject.list
    end
  end

  describe "#lock" do
    let(:env_id) { "rpsec-environment" }

    it "sends a POST to /environments/{id}/lock.json" do
      stub_request(:post, "http://0.0.0.0:1984/environments/#{env_id}/lock.json").
        to_return(status: 200, body: MultiJson.encode([]))

      subject.lock(env_id)
    end
  end

  describe "#provision" do
    let(:plugin_id) { "activemq" }
    let(:env_id) { "rspec-environment" }
    let(:manifest) { MB::Provisioner::Manifest.new }

    it "sends a POST to /environments/{id}.json" do
      req_body = MultiJson.encode(
        manifest: manifest,
        plugin: {
          name: plugin_id,
          version: nil
        }
      )

      stub_request(:post, "http://0.0.0.0:1984/environments/#{env_id}.json").
        with(body: req_body).
        to_return(status: 200, body: empty_response)

      subject.provision(env_id, plugin_id, manifest)
    end
  end

  describe "#unlock" do
    let(:env_id) { "rpsec-environment" }

    it "sends a DELETE to /environments/{id}/lock.json" do
      stub_request(:delete, "http://0.0.0.0:1984/environments/#{env_id}/lock.json").
        to_return(status: 200, body: MultiJson.encode([]))

      subject.unlock(env_id)
    end
  end

  describe "#upgrade" do
    let(:env_id) { "rspec-environment" }
    let(:plugin_id) { "myface" }
    let(:plugin_version) { "1.0.0" }

    it "sends a POST to /environments/{id}/upgrade.json" do
      req_body = MultiJson.encode(
        plugin: {
          name: plugin_id,
          version: plugin_version
        }
      )

      stub_request(:post, "http://0.0.0.0:1984/environments/#{env_id}/upgrade.json").
        with(body: req_body).
        to_return(status: 200, body: empty_response)

      subject.upgrade(env_id, plugin_id, plugin_version)
    end
  end
end
