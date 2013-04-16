require 'spec_helper'

describe MB::ApiClient do
  describe "ClassMethods" do
    describe "::new" do
      subject { described_class.new }

      it "sets a new connection to #pool" do
        subject.connection.should be_a(MB::ApiClient::Connection)
      end

      it "sets a default value for 'host' on the connection" do
        subject.connection.host.should eql("0.0.0.0")
      end

      it "sets a default value for 'port' on the connection" do
        subject.connection.port.should eql(26100)
      end

      it "uses the net_http_persistent adapter" do
        subject.connection.builder.handlers.should include(Faraday::Adapter::NetHttpPersistent)
      end
    end
  end

  subject { described_class.new }

  describe "#config" do
    it "returns an instance of MB::ApiClient::ConfigResource" do
      subject.config.should be_a(MB::ApiClient::ConfigResource)
    end
  end

  describe "#environment" do
    it "returns an instance of MB::ApiClient::EnvironmentResource" do
      subject.environment.should be_a(MB::ApiClient::EnvironmentResource)
    end
  end

  describe "#job" do
    it "returns an instance of MB::ApiClient::JobResource" do
      subject.job.should be_a(MB::ApiClient::JobResource)
    end
  end

  describe "#plugin" do
    it "returns an instance of MB::ApiClient::PluginResource" do
      subject.plugin.should be_a(MB::ApiClient::PluginResource)
    end
  end
end
