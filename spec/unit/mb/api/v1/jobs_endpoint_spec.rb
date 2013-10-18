require 'spec_helper'

describe MB::API::V1::JobsEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.app }

  describe "GET /jobs" do
    it "returns all jobs" do
      get '/jobs'
      last_response.status.should == 200
      JSON.parse(last_response.body).should have(0).items
    end
  end

  describe "GET /jobs/:id" do
    it "returns 404 if missing" do
      get '/jobs/456'
      last_response.status.should == 404
    end
  end
end
