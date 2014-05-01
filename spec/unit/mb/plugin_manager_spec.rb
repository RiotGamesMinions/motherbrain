require 'spec_helper'

describe MotherBrain::PluginManager do
  describe "ClassMethods" do
    subject { described_class }

    describe "::new" do
      context "when 'remote_loading' is disabled" do
        before(:each) do
          described_class.any_instance.stub(eager_loading?: false)
        end

        it "has a nil value for eager_load_timer" do
          subject.new.eager_load_timer.should be_nil
        end
      end

      context "when 'eager_loading' is enabled" do
        before(:each) do
          described_class.any_instance.stub(eager_loading?: true )
        end

        it "sets a Timer for remote_load_timer" do
          subject.any_instance.should_receive(:load_all_remote)

          subject.new.eager_load_timer.should be_a(Timers::Timer)
        end
      end
    end
  end

  subject { described_class.new }

  describe "#install" do
    let(:plugin) { double(name: "rspec", version: "1.2.3") }
    let(:plugin_install_path) { subject.install_path_for(plugin) }

    before { subject.stub_chain(:chef_connection, :cookbook, :download) }

    context "when the remote contains the plugin and it is not installed" do
      before do
        subject.stub(:find).with(plugin.name, plugin.version, remote: true).and_return(plugin)
        subject.stub(:find).with(plugin.name, plugin.version, remote: false).and_return(nil)
      end

      it "searches for the plugin of the given name/version on the remote" do
        subject.should_receive(:find).with(plugin.name, plugin.version, remote: true).and_return(plugin)

        subject.install(plugin.name, plugin.version)
      end

      it "returns the found plugin" do
        expect(subject.install(plugin.name, plugin.version)).to eq(plugin)
      end

      it "downloads the cookbook containing the plugin to the Berkshelf" do
        cookbook_resource = double
        subject.stub_chain(:chef_connection, :cookbook).and_return(cookbook_resource)
        cookbook_resource.should_receive(:download).with(plugin.name, plugin.version, plugin_install_path)

        subject.install(plugin.name, plugin.version)
      end

      it "adds the plugin to the list of plugins" do
        subject.install(plugin.name, plugin.version)

        expect(subject.list).to include(plugin)
      end
    end

    context "when the remote does not have a plugin of the given name/version" do
      before { subject.should_receive(:find).with(plugin.name, plugin.version, remote: true).and_return(nil) }

      it "raises a PluginNotFound error" do
        expect { subject.install(plugin.name, plugin.version) }.to raise_error(MB::PluginNotFound)
      end
    end
  end

  describe "#install_path_for" do
    let(:plugin) { double(name: "rspec", version: "1.2.3") }

    it "returns a Pathname" do
      expect(subject.install_path_for(plugin)).to be_a(Pathname)
    end
  end

  describe "#uninstall" do
    let(:plugin) { double(name: "rpsec", version: "1.2.3") }
    let(:plugin_install_path) { subject.install_path_for(plugin) }

    before do
      subject.add(plugin)
      FileUtils.mkdir_p(plugin_install_path)
    end

    it "returns the uninstalled plugin" do
      expect(subject.uninstall(plugin.name, plugin.version)).to eql(plugin)
    end

    it "removes the plugin from the plugins list" do
      subject.uninstall(plugin.name, plugin.version)

      expect(subject.list).to_not include(plugin)
    end

    it "removes the plugin and it's cookbook from disk" do
      subject.uninstall(plugin.name, plugin.version)

      expect(plugin_install_path).to_not exist
    end

    context "when the plugin of the given name/version is not installed" do
      before { subject.stub(:find).with(plugin.name, plugin.version, remote: false).and_return(nil) }

      it "returns nil" do
        expect(subject.uninstall(plugin.name, plugin.version)).to be_nil
      end
    end
  end

  describe "#latest" do
    let(:name) { "apple" }
    let(:version) { "2.0.0" }

    let(:plugin) do
      double('plugin', name: name, version: version)
    end

    before(:each) do
      subject.stub(list: [plugin])
    end

    it "searches the latest version of the plugin matching the given name" do
      subject.should_receive(:find).with(name, version, remote: false).and_return(plugin)
      subject.latest(name).should eql(plugin)
    end

    context "when no suitable plugin can be found" do
      before(:each) do
        subject.stub(list: [])
      end

      it "returns nil" do
        subject.latest(name).should be_nil
      end
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
      subject.should_receive(:load_installed).with(anything, force: false).exactly(count).times

      subject.load_all
    end

    it "has a plugin for each plugin in the paths" do
      subject.load_all

      subject.list.should have(count).items
      subject.list.should each be_a(MB::Plugin)
    end

    context "when 'remote_loading' is enabled" do
      before(:each) do
        subject.stub(eager_loading?: true)
      end

      it "calls #load_all_remote" do
        subject.should_receive(:load_all_remote)
        subject.load_all
      end
    end
  end

  describe "#load_all_installed" do
    before do
      install_cookbook("ruby", "1.2.3", with_plugin: true)
      install_cookbook("ruby", "2.0.0", with_plugin: true)
      install_cookbook("elixir", "1.3.4", with_plugin: false)
    end

    it "loads each plugin found in the Berkshelf" do
      subject.load_all_installed
      expect(subject.list).to have(2).items
      expect(subject).to have_plugin("ruby", "1.2.3")
      expect(subject).to have_plugin("ruby", "2.0.0")
    end
  end

  describe "#load_all_remote" do
    before do
      described_class.any_instance.stub(async_loading?: false)
      chef_cookbook("ruby", "1.2.3", with_plugin: true)
      chef_cookbook("ruby", "2.0.0", with_plugin: false)
      chef_cookbook("elixir", "1.3.4", with_plugin: true)
    end

    it "loads each plugin found on the Chef Server" do
      subject.load_all_remote
      expect(subject.list).to have(2).items
      expect(subject).to have_plugin("ruby", "1.2.3")
      expect(subject).to have_plugin("elixir", "1.3.4")
    end

    context "given a value for :name" do
      it "only loads each plugin found on the Chef Server matching the given name" do
        subject.load_all_remote(name: "ruby")
        expect(subject.list).to have(1).item
        expect(subject).to have_plugin("ruby", "1.2.3")
      end
    end
  end

  describe "#load_installed" do
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
      subject.load_installed(path)

      subject.list.should include(plugin)
    end
  end

  describe "#load_remote" do
    let(:name) { "nginx" }
    let(:version) { "1.2.0" }
    let(:resource) do
      Ridley::CookbookObject.new(double('client'))
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

          MB::FileSystem.stub(tmpdir: temp_dir)

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
        MB::Application.config.plugin_manager.stub(async_loading: true)
      end

      it "returns true" do
        subject.async_loading?.should be_true
      end
    end

    context "if the plugin manager is not configured for async loading" do
      before(:each) do
        MB::Application.config.plugin_manager.stub(async_loading: false)
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

    it "returns the plugin of the given name and version" do
      subject.find(one.name, one.version).should eql(one)
    end

    it "returns nil if the plugin of a given name and version is not found" do
      subject.find("glade", "3.2.4").should be_nil
    end

    it "returns the latest if a version is not passed" do
      subject.find("apple").should eq(two)
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

    context "when the environment exists but does not have a lock" do
      before do
        environment.stub(cookbook_versions: Hash.new)
        environment_manager.should_receive(:find).with(environment_id).and_return(environment)
      end

      it "satisfies the environment using a wildcard constraint (>= 0.0.0)" do
        subject.should_receive(:satisfy).with(plugin_id, ">= 0.0.0", options)
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

  describe "#for_run_list_entry" do
    let(:cookbook_name)  { "foobook" }
    let(:recipe_name)    { "server"  }
    let(:version)        { "1.1.2"   }
    let(:environment)    { "foo"     }

    let(:run_list_entry) { "recipe[#{cookbook_name}::#{recipe_name}]" }
    let(:run_list_entry_with_version) { run_list_entry.sub(/\]/, "@#{version}]") }

    describe "with run list version" do
      it "should use the run list version definition" do
        subject.should_receive(:find).with(cookbook_name, version, {})
        subject.for_run_list_entry(run_list_entry_with_version)
      end

      it "should use the run list version even if an environment is provided" do
        subject.should_receive(:find).with(cookbook_name, version, {})
        subject.for_run_list_entry(run_list_entry_with_version, environment)
      end
    end

    describe "with environment" do
      it "should use the environment version lock" do
        subject.should_receive(:for_environment).with(cookbook_name, environment, {})
        subject.for_run_list_entry(run_list_entry, environment)
      end
    end

    it "should find the plugin" do
      subject.should_receive(:find).with(cookbook_name, nil, {})
      subject.for_run_list_entry(run_list_entry)
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

    let(:constraint) { ">= 1.2.3" }
    let(:plugin) { double('plugin', name: plugin_id, version: '1.3.0') }

    context "when given a non-wildcard, non-equality constraint" do
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

    context "when given a wild card constraint (>= 0.0.0)" do
      let(:constraint) { ">= 0.0.0" }

      it "returns the latest plugin" do
        subject.should_receive(:latest).with(plugin_id, options).and_return(plugin)

        subject.satisfy(plugin_id, constraint, options).should eql(plugin)
      end
    end
  end

  describe "#installed_versions" do
    before { MB::Berkshelf.stub(cookbooks_path: fixtures_path) }

    context "when the installed cookbooks have at least one version containing a plugin" do
      it "returns an array containing a string for each" do
        versions = subject.installed_versions("myface")
        versions.should have(1).item
        versions.should each be_a(String)
      end
    end

    context "when the installed cookbooks does not have a version containing a plugin" do
      it "returns an empty array" do
        subject.installed_versions("nginx").should be_empty
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
    let(:installed_versions) { [ "1.2.3", "2.0.0" ] }
    let(:remote_versions) { [ "3.0.0" ] }

    context "when given 'false' for the remote argument" do
      before do
        subject.should_not_receive(:remote_versions)
        subject.should_receive(:installed_versions).with(name).and_return(installed_versions)
      end

      it "returns only the installed plugins" do
        expect(subject.versions(name, false)).to eql(installed_versions)
      end
    end

    context "when given 'true' for the remote argument" do
      before do
        subject.should_receive(:remote_versions).with(name).and_return(remote_versions)
        subject.should_receive(:installed_versions).with(name).and_return(installed_versions)
      end

      it "includes the remote versions" do
        expect(subject.versions(name, true)).to include(*remote_versions)
      end

      it "includes the installed versions" do
        expect(subject.versions(name, true)).to include(*installed_versions)
      end

      context "when no plugins are found" do
        let(:remote_versions) { Array.new }
        let(:installed_versions) { Array.new }

        it "raises a PluginNotFound error" do
          expect { subject.versions(name, true) }.to raise_error(MB::PluginNotFound)
        end
      end
    end
  end

  describe "#change_service_state" do
    let(:component_name) { "component_name"   }
    let(:service_name)   { "service_name"     }
    let(:job)            { double(MB::Job)    }
    let(:plugin)         { double(MB::Plugin) }
    let(:environment)    { "environment"      }

    it "should split the service compound name into the component and service names" do
      dynamic_service = double(MB::Gear::DynamicService)
      dynamic_service.stub(:state_change)

      MB::Gear::DynamicService.should_receive(:new).with(component_name, service_name).and_return dynamic_service

      subject.change_service_state(job, "#{component_name}.#{service_name}", plugin, environment, "start")
    end
  end
end
