require 'spec_helper'

describe MB::API::V1::ServerControlEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  after(:each) { MB::Application.resume }
  let(:app) { MB::RestGateway.instance.app }

  describe "PUT /pause" do
    it "pauses the server" do
      put '/pause'
      last_response.status.should == 200
      JSON.parse(last_response.body).should eq("server_status" => "paused")
    end

    it "prevents actions while the server is paused" do
      put '/pause'
      json_post "/environments/environmentname/upgrade",
        MultiJson.dump(plugin: { name: 'pluginname', version: '1.0.0' })
      last_response.status.should == 503
      JSON.parse(last_response.body).should eq("code"=>3330, "message"=>"MotherBrain is paused. It will not accept new requests until it is resumed.")
    end
  end

  describe "PUT /resume" do
    before do
      MB::Application.pause
    end
    
    it "resumes the server" do
      put '/resume'
      last_response.status.should == 200
      JSON.parse(last_response.body).should eq("server_status" => "running")
    end

    it "allows actions while the server is resumed" do
      put '/resume'
      json_post "/environments/environmentname/upgrade",
        MultiJson.dump(plugin: { name: 'pluginname', version: '1.0.0' })
      last_response.status.should == 201
    end
  end

  describe "PUT /stop" do
    it "stops the server" do
      put '/stop'
      last_response.status.should == 202
      JSON.parse(last_response.body).should eq("server_status" => "stopping")
    end
  end
end
