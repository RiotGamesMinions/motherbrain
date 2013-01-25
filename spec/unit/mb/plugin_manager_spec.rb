require 'spec_helper'

describe MotherBrain::PluginManager do
  subject { described_class.new }

  describe "#load_all" do
    let(:paths) do
      [
        tmp_path.join('plugin_one'),
        tmp_path.join('plugin_two'),
        tmp_path.join('plugin_three')
      ]
    end

    before(:each) do
      subject.clear_plugins
      paths.each do |path|
        generate_cookbook(SecureRandom.hex(16), path, with_plugin: true)
      end

      MB::Berkshelf.stub(:cookbooks).and_return(paths)
    end

    it "sends a load message to self with each plugin found in the berkshelf" do
      subject.should_receive(:load).with(anything).exactly(3).times

      subject.load_all
    end

    it "has a plugin for each plugin in the paths" do
      subject.load_all

      subject.plugins.should have(3).items
      subject.plugins.should each be_a(MB::Plugin)
    end
  end

  describe "#load" do
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
      subject.load(path)

      subject.plugins.should include(plugin)
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

    context "when the plugin is already added" do
      it "raises an AlreadyLoaded error" do
        subject.add(plugin)

        lambda {
          subject.add(plugin)
        }.should raise_error(MB::AlreadyLoaded)
      end

      context "when given 'true' for the ':force' option" do
        it "does not raise an AlreadyLoaded error" do
          subject.add(plugin)

          lambda {
            subject.add(plugin, force: true)
          }.should_not raise_error(MB::AlreadyLoaded)
        end
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

    context "when no version is given" do
      it "returns the latest version of the plugin" do
        subject.find(two.name).should eql(two)
      end

      it "returns nil a plugin of the given name is not found" do
        subject.find("glade").should be_nil
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

      subject.plugins.should be_empty
    end
  end
end
