require 'spec_helper'

describe MB::ApiClient::PluginResource do
  subject { MB::ApiClient.new.plugin }

  describe "#commands" do
    let(:plugin_id) { "rspec-test" }

    context "when no version argument is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/commands.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/latest/commands.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.commands(plugin_id).should be_a(Hash)
      end
    end

    context "when a version argument is given" do
      let(:version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{version}/commands.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0/commands.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.commands(plugin_id, version).should be_a(Hash)
      end
    end
  end

  describe "#components" do
    let(:plugin_id) { "rspec-test" }

    context "when no version argument is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/components.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/latest/components.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.components(plugin_id).should be_a(Hash)
      end
    end

    context "when a version argument is given" do
      let(:version) { "1.0.0" }
      
      it "returns decoded JSON from /plugins/{plugin_id}/{version}/components.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0/components.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.components(plugin_id, version).should be_a(Hash)
      end
    end
  end

  describe "#component_commands" do
    let(:plugin_id) { "rpsec-test" }
    let(:component_id) { "some-component" }

    it "returns decoded JSON from /plugins/{plugin_id}/{version}/components/{component_id}/commands.json" do
      stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0/components/#{component_id}/commands.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.component_commands(plugin_id, "1.0.0", component_id).should be_a(Hash)
    end

    context "when a version argument of 'nil' is given" do
      it "returns decoded JSON from /plugins/{plugin_id}/latest/components/{component_id}/commands.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/latest/components/#{component_id}/commands.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.component_commands(plugin_id, nil, component_id).should be_a(Hash)
      end
    end
  end

  describe "#find" do
    let(:plugin_id) { "rspec-test" }

    it "returns decoded JSON from /plugins/{plugin_id}.json" do
      stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.find(plugin_id).should be_a(Hash)
    end

    context "when given a version" do
      let(:plugin_version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{plugin_version}.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.find(plugin_id, plugin_version).should be_a(Hash)
      end
    end
  end

  describe "#latest" do
    let(:plugin_id) { "rspec-test" }

    it "returns decoded JSON from /plugins/{plugin_id}.json" do
      stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/latest.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.latest(plugin_id).should be_a(Hash)
    end
  end

  describe "#list" do
    before(:each) do
      stub_request(:get, "http://0.0.0.0:1984/plugins.json").
        to_return(status: 200, body: MultiJson.encode(MB::PluginManager.instance.list))
    end

    it "returns an Array" do
      subject.list.should be_a(Array)
    end
  end
end
