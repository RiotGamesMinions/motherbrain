require 'spec_helper'

describe MB::ApiClient::ConfigResource do
  subject { MB::ApiClient.new }

  describe "#show" do
    before(:each) do
      stub_request(:get, "http://0.0.0.0:26100/config.json").
        to_return(status: 200, body: MB::Application.config.to_json)
    end

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
