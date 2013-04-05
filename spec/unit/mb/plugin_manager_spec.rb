require 'spec_helper'

describe MotherBrain::PluginManager do
  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      context "when 'remote_loading' is disabled" do
        before(:each) do
          described_class.any_instance.stub(:eager_loading?) { false }
        end

        it "has a nil value for eager_load_timer" do
          subject.new.eager_load_timer.should be_nil
        end
      end

      context "when 'eager_loading' is enabled" do
        before(:each) do
          described_class.any_instance.stub(:eager_loading?) { true }
        end

        it "sets a Timer for remote_load_timer" do
          subject.any_instance.should_receive(:load_all_remote)

          subject.new.eager_load_timer.should be_a(Timers::Timer)
        end
      end
    end
  end

  subject { described_class.new }

  describe "#latest" do
    let(:name) { "apple" }
    let(:version) { "2.0.0" }

    let(:plugin) do
      double('plugin', name: name, version: version)
    end

    before(:each) do
      subject.stub(local_versions: ["1.0.0", version])
    end

    it "searches the latest version of the plugin matching the given name" do
      subject.should_receive(:find).with(name, version, remote: false).and_return(plugin)
      subject.latest(name).should eql(plugin)
    end
  end

  describe "#load_all" do
    let(:count) { 3 }

    before(:each) do
      subject.clear_plugins
      paths = Array.new
      
      count.times do
        paths << generate_cookbook(SecureRandom.hex(16), with_plugin: true)
      end

      MB::Berkshelf.stub(:cookbooks).and_return(paths)
    end

    it "sends a load message to self with each plugin found in the berkshelf" do
      subject.should_receive(:load_local).with(anything, force: false).exactly(count).times

      subject.load_all
    end

    it "has a plugin for each plugin in the paths" do
      subject.load_all

      subject.list.should have(count).items
      subject.list.should each be_a(MB::Plugin)
    end

    context "when 'remote_loading' is enabled" do
      before(:each) do
        subject.stub(:eager_loading?) { true }
      end

      it "calls #load_all_remote" do
        subject.should_receive(:load_all_remote)
        subject.load_all
      end
    end
  end

  describe "#load_local" do
    let(:plugin) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    let(:path) { '/tmp/one/apple-1.0.0' }

    before(:each) do
      MB::Plugin.stub(:from_path).with(path).and_return(plugin)
    end

    it "adds an instantiated plugin to the hash of plugins" do
      subject.load_local(path)

      subject.list.should include(plugin)
    end
  end

  describe "#load_remote" do
    let(:name) { "nginx" }
    let(:version) { "1.2.0" }
    let(:resource) do
      Ridley::CookbookResource.new(double('client'))
    end

    before(:each) do
      subject.ridley.stub_chain(:cookbook, :find).and_return(resource)
    end

    context "when the cookbook doesn't contain a motherbrain plugin" do
      before(:each) { resource.stub(has_motherbrain_plugin?: false) }

      it "returns nil if resource doesn't contain a motherbrain plugin" do
        subject.load_remote(name, version).should be_nil
      end
    end

    context "when the cookbook contains a motherbrain plugin" do
      before(:each) { resource.stub(has_motherbrain_plugin?: true) }
      let(:temp_dir) { MB::FileSystem.tmpdir }

      context "and the files are transferred successfully" do
        before(:each) do
          File.write(File.join(temp_dir, MB::Plugin::PLUGIN_FILENAME), "# blank plugin")

          MB::FileSystem.stub(:tmpdir) { temp_dir }

          resource.stub(:download_file).and_return(true)

          json_metadata = File.read(fixtures_path.join('cb_metadata.json'))
          resource.stub_chain(:metadata, :to_json).and_return(json_metadata)
        end

        it "adds the plugin to the set of plugins" do
          subject.load_remote(name, version)

          subject.list.should have(1).item
        end

        it "cleans up the generated temporary files" do
          subject.load_remote(name, version)

          File.exist?(temp_dir).should be_false
        end
      end

      context "when the plugin is not downloaded successfully" do
        before(:each) { resource.stub(:download_file).and_return(nil) }

        it "returns nil" do
          subject.load_remote(name, version).should be_nil
        end
      end
    end

    context "when the remote does not have a cookbook of the given name/version" do
      before(:each) { subject.ridley.stub_chain(:cookbook, :find).and_return(nil) }

      it "returns nil" do
        subject.load_remote(name, version).should be_nil
      end
    end
  end

  describe "#add" do
    let(:plugin) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    it "returns the added plugin" do
      subject.add(plugin).should eql(plugin)
    end

    it "adds the plugin to the Set of plugins" do
      subject.add(plugin)

      subject.list.should include(plugin)
    end

    context "when the plugin is already added" do
      it "returns nil" do
        subject.add(plugin)
        
        subject.add(plugin).should be_nil
      end

      context "when given 'true' for the ':force' option" do
        it "adds the plugin anyway" do
          subject.add(plugin)

          subject.add(plugin, force: true).should eql(plugin)
        end

        it "doesn't add a duplicate plugin" do
          subject.add(plugin)
          subject.add(plugin)

          subject.list.should have(1).item
        end
      end
    end
  end

  describe "#async_loading?" do
    context "if the plugin manager is configured for async loading" do
      before(:each) do
        MB::Application.config.plugin_manager.stub(:async_loading) { true }
      end

      it "returns true" do
        subject.async_loading?.should be_true
      end
    end

    context "if the plugin manager is not configured for async loading" do
      before(:each) do
        MB::Application.config.plugin_manager.stub(:async_loading) { false }
      end

      it "returns false" do
        subject.async_loading?.should be_false
      end
    end
  end

  describe "#find" do
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
    let(:three) do
      metadata = MB::CookbookMetadata.new do
        name 'orange'
        version '2.0.0'
      end
      MB::Plugin.new(metadata)
    end

    before(:each) do
      subject.add(one)
      subject.add(two)
      subject.add(three)
    end

    context "when a version is given" do
      it "returns the plugin of the given name and version" do
        subject.find(one.name, one.version).should eql(one)
      end

      it "returns nil if the plugin of a given name and version is not found" do
        subject.find("glade", "3.2.4").should be_nil
      end
    end
  end

  describe "#for_environment" do
    let(:plugin_id) { "rspec-test" }
    let(:environment_id) { "rspec-testenv" }
    let(:environment) do
      double('environment',
        name: environment_id,
        cookbook_versions: {
          plugin_id => ">= 1.2.3"
        }
      )
    end
    let(:options) do
      {
        remote: true
      }
    end

    context "when the environment exists" do
      before(:each) do
        environment_manager.should_receive(:find).with(environment_id).and_return(environment)
      end

      it "attempts to satisfy the environment's plugin (cookbook) constraint" do
        subject.should_receive(:satisfy).with(plugin_id, ">= 1.2.3", options)
        subject.for_environment(plugin_id, environment_id, options)
      end
    end

    context "when the environment does not exist" do
      before(:each) do
        environment_manager.should_receive(:find).with(environment_id).
          and_raise(MB::EnvironmentNotFound.new(environment_id))
      end

      it "raises an EnvironmentNotFound error" do
        expect {
          subject.for_environment(plugin_id, environment_id)
        }.to raise_error(MB::EnvironmentNotFound)
      end
    end
  end

  describe "#clear_plugins" do
    let(:plugin) do
      metadata = MB::CookbookMetadata.new do
        name 'apple'
        version '1.0.0'
      end
      MB::Plugin.new(metadata)
    end

    it "clears any loaded plugins" do
      subject.add(plugin)
      subject.clear_plugins

      subject.list.should be_empty
    end
  end

  describe "#list" do
    it "returns an Array of plugins" do
      result = subject.list

      result.should be_a(Array)
      result.should each be_a(MB::Plugin)
    end

    context "given 'true' for the :remote option" do
      it "loads the remote plugins before returning" do
        subject.should_receive(:load_all_remote)

        subject.list(remote: true)
      end
    end
  end

  describe "#satisfy" do
    let(:plugin_id) { "rspec-test" }
    let(:versions) do
      [
        "1.0.0",
        "1.2.3",
        "1.3.0"
      ]
    end
    let(:options) do
      {
        remote: false
      }
    end

    context "when the remote has a plugin which satisfies the constraint" do
      let(:constraint) { ">= 1.2.3" }
      let(:plugin) { double('plugin', name: 'nginx', version: '1.3.0') }

      before(:each) do
        subject.should_receive(:versions).with(plugin_id, options[:remote]).and_return(versions)
      end

      it "returns the best plugin for the given constraint" do
        subject.should_receive(:find).with(plugin_id, "1.3.0", remote: false).and_return(plugin)
        subject.satisfy(plugin_id, constraint, options).should eql(plugin)
      end
    end

    context "when given a constraint containing an eqluality operator" do
      let(:constraint) { "= 1.0.0" }

      it "does not attempt to get a list of all versions" do
        subject.should_not_receive(:versions)

        subject.satisfy(plugin_id, constraint, options)
      end

      context "when the :remote option is set to true" do
        before { options[:remote] = true }

        it "attempts to eagerly load a plugin of the same name/version from the remote" do
          subject.should_receive(:load_remote).with(plugin_id, "1.0.0")

          subject.satisfy(plugin_id, constraint, options)
        end
      end
    end

    context "when the :remote option is set to true" do
      let(:constraint) { "= 1.0.0" }

      before do
        options[:remote] = true
      end

      it "attempts to load the matching plugin from the remote" do
        subject.should_receive(:load_remote).with(plugin_id, "1.0.0")
        subject.should_receive(:find).with(plugin_id, "1.0.0", remote: false).and_return(versions[0])

        subject.satisfy(plugin_id, constraint, options)
      end
    end
  end

  describe "#local_versions" do
    before { MB::Berkshelf.stub(cookbooks_path: fixtures_path) }

    context "when the local cache has at least one cookbook containing a plugin of the given name" do
      it "returns an array containing a string for each" do
        versions = subject.local_versions("myface")
        versions.should have(1).item
        versions.should each be_a(String)
      end
    end

    context "when there is a plugin found by local_plugin?" do
      let(:version) { "2.0.0" }
      let(:plugin) { double('plugin', version: version)}

      before(:each) do
        subject.stub(:load_local_plugin).and_return(plugin)
        subject.stub(:local_plugin?).and_return(true)
      end
      
      it "returns an array containing the version of the local plugin" do
        versions = subject.local_versions("my_local_plugin")
        versions.should have(1).item
        versions.should each be_a(String)
      end

      it "returns an array containing all the versions of the local plugin" do
        versions = subject.local_versions("myface")
        versions.should have(2).items
        versions.should each be_a(String)
      end
    end

    context "when the local cache does not have a cookbook containing a plugin of the given name" do
      it "returns an empty array" do
        subject.local_versions("nginx").should be_empty
      end
    end
  end

  describe "#remote_versions" do
    let(:name) { "nginx" }
    let(:chef_connection) { double('chef-connection') }

    let(:versions) do
      [
        "1.0.0",
        "2.0.0"
      ]
    end

    before do
      subject.stub(chef_connection: chef_connection)
      chef_connection.stub_chain(:cookbook, :versions).with(name).and_return(versions)
    end

    it "attempts to load a plugin for every version of the cookbook present on the chef server" do
      versions.each do |version|
        subject.should_receive(:load_remote).with(name, version).and_return(nil)
      end

      subject.remote_versions(name)
    end

    context "when the cookbook versions on the remote contain a plugin" do
      before do
        versions.each do |version|
          subject.should_receive(:load_remote).with(name, version).and_return(double(version: version))
        end
      end

      it "returns an array of strings including the versions" do
        subject.remote_versions(name).should include(*versions)
      end
    end

    context "when the cookbook versions on the remote do not contain a plugin" do
      before do
        versions.each do |version|
          subject.should_receive(:load_remote).with(name, version).and_return(nil)
        end
      end

      it "returns an empty array of strings" do
        subject.remote_versions(name).should be_empty
      end
    end

    context "when the remote chef server does not contain any cookbooks of the given name" do
      let(:versions) { Array.new }

      before do
        chef_connection.stub_chain(:cookbook, :versions).with(name).and_return(versions)
      end

      it "returns an empty array" do
        subject.remote_versions(name).should be_empty
      end
    end
  end

  describe "#versions" do
    let(:name) { "nginx" }
    let(:local_versions) { [ "1.2.3", "2.0.0" ] }
    let(:remote_versions) { [ "3.0.0" ] }

    before do
      subject.should_not_receive(:remote_versions)
    end

    it "returns only the local plugins" do
      subject.should_receive(:local_versions).with(name).and_return(local_versions)
      subject.versions(name).should eql(local_versions)
    end

    context "when given 'true' for the remote argument" do
      before do
        subject.should_receive(:remote_versions).with(name).and_return(remote_versions)
        subject.should_receive(:local_versions).with(name).and_return(local_versions)
      end

      it "includes the remote versions" do
        subject.versions(name, true).should include(*remote_versions)
      end

      it "includes the local versions" do
        subject.versions(name, true).should include(*local_versions)
      end
    end

    context "when no plugins are found" do
      before do
        subject.stub(:local_versions).with(name) { Array.new }
        subject.stub(:remote_versions).with(name) { Array.new }
      end

      it "raises a PluginNotFound error" do
        expect {
          subject.versions(name, true)
        }.to raise_error(MB::PluginNotFound)
      end
    end
  end
end
