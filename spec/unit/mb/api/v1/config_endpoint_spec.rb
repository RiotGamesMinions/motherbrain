require 'spec_helper'

describe MB::API::V1::ConfigEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.rack_app }

  describe "GET /config" do
    let(:current_config) { MB::Application.config }

    it "returns a MB::Config as JSON" do
      get '/config'
      last_response.status.should == 200
      MB::Config.from_json(last_response.body).should be_a(MB::Config)
    end
  end
end
