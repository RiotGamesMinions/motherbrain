require 'spec_helper'

describe MB::REST::Gateway do
  include Rack::Test::Methods

  before(:all) { @gateway = MB::REST::Gateway.new }
  after(:all) { @gateway.terminate }

  let(:app) { @gateway.rack_app }
  subject { @gateway }

  describe "#rack_app" do
    it "returns MB::REST::API" do
      subject.rack_app.should be_a(MB::REST::API)
    end
  end

  describe "API" do
    describe "GET /config" do
      let(:current_config) { MB::Application.config }

      it "returns a MB::Config as JSON" do
        get '/config'
        last_response.status.should == 200
        MB::Config.from_json(last_response.body).should be_a(MB::Config)
      end
    end

    describe "GET /plugins" do
      it "returns all loaded plugins as JSON" do
        get '/plugins'
        last_response.status.should == 200
        JSON.parse(last_response.body).should have(MB::Application.plugin_manager.plugins.length).items
      end
    end
  end

  describe "API Error handling" do
    describe "MB errors" do
      it "returns a JSON response containing a code and message" do
        get '/mb_error'
        last_response.status.should == 500
        json = JSON.parse(last_response.body)

        json.should have_key("code")
        json["code"].should eql(99)
        json.should have_key("message")
        json["message"].should eql("a nice error message")
      end
    end

    describe "Unknown errors" do
      it "returns a JSON response containing a -1 code and message" do
        get '/unknown_error'
        last_response.status.should == 500
        json = JSON.parse(last_response.body)

        json.should have_key("code")
        json["code"].should eql(-1)
        json.should have_key("message")
        json["message"].should eql("an unknown error occured")
      end
    end
  end
end
