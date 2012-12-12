require 'spec_helper'

describe MB::REST::Client do
  subject { described_class.new }

  describe "#config" do
    before(:each) do
      stub_request(:get, "http://0.0.0.0:1984/config.json").
        to_return(status: 200, body: MB::Application.config.to_json)
    end

    it "returns an instance of MB::Config" do
      subject.config.should be_a(MB::Config)
    end
  end
end
