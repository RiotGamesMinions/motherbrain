require 'spec_helper'

describe MB::API::V1 do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.app }

  describe "API Error handling" do
    describe "MB errors" do
      it "returns a JSON response containing a code and message" do
        get '/mb_error'
        last_response.status.should == 500
        json = JSON.parse(last_response.body)

        json.should have_key("code")
        json["code"].should eql(1000)
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
