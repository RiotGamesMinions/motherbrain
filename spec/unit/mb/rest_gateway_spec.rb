require 'spec_helper'

describe MB::RestGateway do
  include Rack::Test::Methods

  before(:all) { @gateway = MB::RestGateway.new }
  after(:all) { @gateway.terminate }

  let(:app) { @gateway.rack_app }
  subject { @gateway }

  describe "#rack_app" do
    it "returns MB::Api" do
      subject.rack_app.should be_a(MB::Api)
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

        post "/environments/#{environment_id}/upgrade",
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
