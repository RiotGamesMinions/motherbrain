require 'spec_helper'

describe MB::ApiClient::PluginResource do
  subject { MB::ApiClient.new.plugin }

  describe "#commands" do
    let(:plugin_id) { "rspec-test" }

    context "when no version argument is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/commands.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/latest/commands.json").
          to_return(status: 200)

        subject.commands(plugin_id)
      end
    end

    context "when a version argument is given" do
      let(:version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{version}/commands.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/1_0_0/commands.json").
          to_return(status: 200)

        subject.commands(plugin_id, version)
      end
    end
  end

  describe "#components" do
    let(:plugin_id) { "rspec-test" }

    context "when no version argument is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/components.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/latest/components.json").
          to_return(status: 200)

        subject.components(plugin_id)
      end
    end

    context "when a version argument is given" do
      let(:version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{version}/components.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/1_0_0/components.json").
          to_return(status: 200)

        subject.components(plugin_id, version)
      end
    end
  end

  describe "#component_commands" do
    let(:plugin_id) { "rpsec-test" }
    let(:component_id) { "some-component" }

    it "returns decoded JSON from /plugins/{plugin_id}/{version}/components/{component_id}/commands.json" do
      stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/1_0_0/components/#{component_id}/commands.json").
        to_return(status: 200)

      subject.component_commands(plugin_id, "1.0.0", component_id)
    end

    context "when a version argument of 'nil' is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/components/{component_id}/commands.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/latest/components/#{component_id}/commands.json").
          to_return(status: 200)

        subject.component_commands(plugin_id, nil, component_id)
      end
    end
  end

  describe "#find" do
    let(:plugin_id) { "rspec-test" }

    it "returns decoded JSON from /plugins/{plugin_id}.json" do
      stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}.json").to_return(status: 200)

      subject.find(plugin_id)
    end

    context "when given a version" do
      let(:plugin_version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{plugin_version}.json" do
        stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/1_0_0.json").to_return(status: 200)

        subject.find(plugin_id, plugin_version)
      end
    end
  end

  describe "#latest" do
    let(:plugin_id) { "rspec-test" }

    it "returns decoded JSON from /plugins/{plugin_id}.json" do
      stub_request(:get, "http://0.0.0.0:26100/plugins/#{plugin_id}/latest.json").to_return(status: 200)

      subject.latest(plugin_id)
    end
  end

  describe "#list" do
    it "performs a GET request to /plugins.json" do
      stub_request(:get, "http://0.0.0.0:26100/plugins.json").to_return(status: 200)

      subject.list
    end
  end
end
