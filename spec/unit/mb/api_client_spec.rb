require 'spec_helper'

describe MB::ApiClient do
  describe "ClassMethods" do
    describe "::new" do
      subject { described_class.new }

      it "sets a new connection to #pool" do
        subject.pool.should be_a(MB::ApiClient::Connection)
      end

      it "sets a default value for 'host' on the connection" do
        subject.pool.host.should eql("0.0.0.0")
      end

      it "sets a default value for 'port' on the connection" do
        subject.pool.port.should eql(1984)
      end

      it "uses the net_http_persistent adapter" do
        subject.pool.builder.handlers.should include(Faraday::Adapter::NetHttpPersistent)
      end
    end
  end

  subject { described_class.new }

  describe "#config" do
    before(:each) do
      stub_request(:get, "http://0.0.0.0:1984/config.json").
        to_return(status: 200, body: MB::Application.config.to_json)
    end

    it "returns an instance of MB::ApiClient::ConfigResource" do
      subject.config.should be_a(MB::ApiClient::ConfigResource)
    end

    describe "#show" do
      it "returns an instance of MB::Config" do
        subject.config.show.should be_a(MB::Config)
      end

      it "allows future values" do
        future = subject.config.future.show
        future.should be_a(Celluloid::Future)
        future.value.should be_a(MB::Config)
      end
    end
  end

  describe "#plugin" do
    it "returns an instance of MB::ApiClient::PluginResource" do
      subject.plugin.should be_a(MB::ApiClient::PluginResource)
    end

    describe "#find" do
      let(:plugin_id) { "rspec-test" }
      before(:each) do
        stub_request(:get, "http://0.0.0.0:1984/plugins/#{plugin_id}.json").
          to_return(status: 200, body: MultiJson.encode({}))
      end

      it "returns a Hash" do
        subject.plugin.find(plugin_id).should be_a(Hash)
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
end
