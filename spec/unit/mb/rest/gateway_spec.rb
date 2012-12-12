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
end
