require 'spec_helper'

describe MB::API::V1::ConfigEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.app }

  describe "GET /environments" do
    let(:environments) { Array.new }

    before(:each) do
      environment_manager.should_receive(:list).and_return(environments)
    end

    it "returns a 200" do
      get '/environments'
      last_response.status.should == 200
    end
  end

  describe "POST /environments/:environment_id/upgrade" do
    let(:environment_id) { "rpsec_test" }
    let(:plugin_id) { "myface" }
    let(:plugin_version) { "1.0.0" }

    it "delegates to the upgrade manager returns 201" do
      plugin = double('plugin')
      job = MB::Job.new(:test).ticket
      plugin_manager.should_receive(:find).with(plugin_id, plugin_version).and_return(plugin)
      upgrade_manager.should_receive(:async_upgrade).with(environment_id, plugin, anything).and_return(job)

      json_post "/environments/#{environment_id}/upgrade",
        MultiJson.dump(plugin: { name: plugin_id, version: plugin_version })

      last_response.status.should == 201
    end
  end

  describe "GET /environments/:environment_id/commands/:plugin_id" do
    let(:environment_id) { "rspec_test" }
    let(:plugin_id) { "myface" }
    let(:plugin) { double('plugin', commands: []) }

    it "returns the commands of the plugin for the environment" do
      plugin_manager.should_receive(:for_environment).with(plugin_id, environment_id).and_return(plugin)

      get "/environments/#{environment_id}/commands/#{plugin_id}"
      last_response.status.should == 200
      MultiJson.decode(last_response.body).should eql(plugin.commands)
    end
  end

  describe "GET /environments/:environment_id/commands/:plugin_id/:component_id" do
    let(:environment_id) { "rspec_test" }
    let(:plugin_id) { "myface" }
    let(:component_id) { "appsrv" }
    let(:component) { double('component', commands: []) }
    let(:plugin) { double('plugin') }

    it "returns the commands of the plugin for the environment" do
      plugin.should_receive(:component!).with(component_id).and_return(component)
      plugin_manager.should_receive(:for_environment).with(plugin_id, environment_id).and_return(plugin)

      get "/environments/#{environment_id}/commands/#{plugin_id}/#{component_id}"
      last_response.status.should == 200
      MultiJson.decode(last_response.body).should eql(component.commands)
    end
  end
end
