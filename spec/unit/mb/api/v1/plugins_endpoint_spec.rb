require 'spec_helper'

describe MB::API::V1::JobsEndpoint do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.rack_app }

  describe "GET /plugins" do
    it "returns all loaded plugins as JSON" do
      get '/plugins'
      last_response.status.should == 200
      JSON.parse(last_response.body).should have(MB::Application.plugin_manager.list.length).items
    end
  end

  describe "GET /plugins/:name" do
    context "when a matching plugin is found" do
      let(:one) do
        metadata = MB::CookbookMetadata.new do
          name 'apple'
          version '1.0.0'
        end
        MB::Plugin.new(metadata)
      end

      let(:two) do
        metadata = MB::CookbookMetadata.new do
          name 'apple'
          version '2.0.0'
        end
        MB::Plugin.new(metadata)
      end

      before(:each) do
        MB::PluginManager.instance.clear_plugins
        MB::PluginManager.instance.add(one)
        MB::PluginManager.instance.add(two)
        get '/plugins/apple'
      end

      it "returns 200" do
        last_response.status.should == 200
      end

      it "has an item for each plugin version" do
        JSON.parse(last_response.body).should have(2).items
      end
    end

    context "when no plugin versions are found for plugin" do
      before(:each) { get '/plugins/test' }

      it "returns 200" do
        last_response.status.should == 200
      end

      it "returns an empty array" do
        result = JSON.parse(last_response.body)
        result.should be_empty
      end
    end
  end

  describe "GET /plugins/:name/latest" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    let(:two) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '2.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      MB::PluginManager.instance.add(two)
      get '/plugins/apple/latest'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns 200" do
      last_response.status.should == 200
    end

    it "returns the latest plugin version" do
      response = JSON.parse(last_response.body)
      response["name"].should eql("apple")
      response["version"]["major"].should eql(2)
      response["version"]["minor"].should eql(0)
      response["version"]["patch"].should eql(0)
    end
  end

  describe "GET /plugins/:name/:version" do
    context "when the a matching plugin is found" do
      let(:one) do
        metadata = MB::CookbookMetadata.new do
          name 'apple'
          version '1.0.0'
        end
        MB::Plugin.new(metadata)
      end

      before(:each) do
        MB::PluginManager.instance.add(one)
      end

      after(:each) do
        MB::PluginManager.instance.clear_plugins
      end

      it "returns a 200 response" do
        get '/plugins/apple/1_0_0'
        last_response.status.should == 200
      end

      it "returns a plugin for the given name and version" do
        get '/plugins/apple/1_0_0'
        response = JSON.parse(last_response.body)
        response["name"].should eql("apple")
      end
    end

    context "when plugin not found" do
      before(:each) { get '/plugins/test/1_0_0' }

      it "returns a 404 response" do
        last_response.status.should == 404
      end

      it "has the error code for PluginNotFound" do
        result = JSON.parse(last_response.body)
        result.should have_key("code")
        result["code"].should be_error_code(MB::PluginNotFound)
      end
    end

    context "when an invalid version string is given" do
      before(:each) { get '/plugins/test/fake_version' }

      it "returns a 400 response" do
        last_response.status.should == 400
      end
    end
  end

  describe "GET /plugins/:name/latest/commands" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/latest/commands'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end

  describe "GET /plugins/:name/:version/commands" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/1_0_0/commands'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end

  describe "GET /plugins/:name/latest/components" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/latest/components'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end

  describe "GET /plugins/:name/:version/components" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/1_0_0/components'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end

  describe "GET /plugins/:name/latest/components/:component_id/commands" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/latest/components/myface/commands'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end

  describe "GET /plugins/:name/:version/components/:component_id/commands" do
    let(:one) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata) do
        component "myface" do; end
      end
    end

    before(:each) do
      MB::PluginManager.instance.add(one)
      get '/plugins/apple/1_0_0/components/myface/commands'
    end

    after(:each) do
      MB::PluginManager.instance.clear_plugins
    end

    it "returns a 200 response" do
      last_response.status.should == 200
    end
  end
end
