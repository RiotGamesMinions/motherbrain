require 'spec_helper'

describe MB::ApiClient::PluginResource do
  subject { MB::ApiClient.new }

  describe "#find" do
    let(:plugin_id) { "rspec-test" }

    it "returns decoded JSON from /plugins/{plugin_id}.json" do
      stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.plugin.find(plugin_id).should be_a(Hash)
    end

    context "when given a version" do
      let(:plugin_version) { "1.0.0" }

      it "returns decoded JSON from /plugins/{plugin_id}/{plugin_version}.json" do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}/1_0_0.json").
          to_return(status: 200, body: MultiJson.encode({}))

        subject.plugin.find(plugin_id, plugin_version).should be_a(Hash)
      end
    end
  end

  describe "#list" do
    before(:each) do
      stub_request(:get, "http://0.0.0.0:1984/plugins.json").
        to_return(status: 200, body: MultiJson.encode(MB::PluginManager.instance.plugins))
    end

    it "returns an Array" do
      subject.plugin.list.should be_a(Array)
    end
  end
end
