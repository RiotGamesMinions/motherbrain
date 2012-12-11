require 'spec_helper'

describe MotherBrain::PluginManager do
  before(:each) do
    @config.stub(:plugin_paths) { MB::PluginManager.default_paths }
  end

  describe "ClassMethods" do
    subject { MB::PluginManager }

    describe '::new' do
      it 'sets the paths attribute to a set of pathnames pointing to the default paths' do
        obj = subject.new

        obj.paths.should be_a(Set)
        obj.paths.should each be_a(Pathname)
        subject.default_paths.each do |path|
          obj.paths.collect(&:to_s).should include(path)
        end
      end
    end

    describe "::default_paths" do
      it "returns a Set" do
        subject.default_paths.should be_a(Set)
      end

      it "contains a path to the MB::FileSystem.plugins path" do
        subject.default_paths.should include(MB::FileSystem.plugins.to_s)
      end

      it "contains a path to '.mb/plugins' in the local directory" do
        subject.default_paths.should include(File.expand_path('.mb/plugins'))
      end

      context "given ENV['MB_PLUGIN_PATH'] is set" do
        let(:plugin_path) { "/tmp/motherbrain_spec" }

        before(:each) do
          @original = ENV['MB_PLUGIN_PATH']
          set_plugin_path(plugin_path)
        end

        after(:each) { set_plugin_path(@original) }

        it "returns a Set only containing the path in the environment variable" do
          subject.default_paths.should have(1).item
          subject.default_paths.should include(plugin_path)
        end
      end
    end
  end

  subject { MB::PluginManager.new }

  describe '#load_all' do
    let(:paths) do
      [
        tmp_path.join('plugin_one'),
        tmp_path.join('plugin_two'),
        tmp_path.join('plugin_three')
      ]
    end

    before(:each) do
      subject.clear_paths

      paths.each do |path|
        generate_plugin(SecureRandom.hex(16), '1.0.0', path)

        subject.add_path(path)
      end
    end

    it 'sends a load message to self with each plugin found in the paths' do
      subject.should_receive(:load).with(anything).exactly(3).times

      subject.load_all
    end

    it 'has a plugin for each plugin in the paths' do
      subject.load_all

      subject.plugins.should have(3).items
      subject.plugins.should each be_a(MB::Plugin)
    end
  end

  describe '#load' do
    let(:path) { '/tmp/one/plugin.rb' }
    let(:plugin) { double('plugin', name: 'reset', version: '1.2.3', id: 'reset-1.2.3') }

    before(:each) do
      MB::Plugin.stub(:from_file).with(path).and_return(plugin)
    end

    it 'adds an instantiated plugin to the hash of plugins' do
      subject.load(path)

      subject.plugins.should include(plugin)
    end

    context 'when a plugin is already loaded' do
      it 'raises an AlreadyLoaded error' do
        subject.load(path)

        lambda {
          subject.load(path)
        }.should raise_error(MB::AlreadyLoaded)
      end
    end
  end

  describe '#add_path' do
    let(:path) { '/tmp/one' }
    before(:each) { subject.clear_paths }

    it 'adds the given string as a pathname to the set' do
      subject.add_path(path)

      subject.paths.should have(1).item
      subject.paths.first.should be_a(Pathname)
      subject.paths.first.to_s.should eql('/tmp/one')
    end

    context 'when a path already exists in the set' do
      it 'does not add a duplicate item to the set' do
        subject.add_path(path)
        subject.add_path(path)

        subject.paths.should have(1).item
      end
    end

    context 'given a pathname object' do
      let(:path) { Pathname.new('/tmp/one') }

      it 'adds the pathname to the set' do
        subject.add_path(path)

        subject.paths.should have(1).item
      end
    end
  end

  describe '#remove_path' do
    let(:path) { Pathname.new('/tmp/one') }
    before(:each) do
      subject.clear_paths
      subject.add_path(path)
    end

    it 'removes the given pathname from the set' do
      subject.remove_path(path)

      subject.paths.should have(0).items
    end
  end

  describe '#plugin' do
    let(:path) { '/tmp/one' }
    let(:plugin) { double('plugin', name: 'reset', version: '1.2.3', id: :'reset-1.2.3') }

    before(:each) do
      MB::Plugin.stub(:from_file).with(path).and_return(plugin)
      subject.load(path)
    end

    it 'it returns the plugin of the given name and version' do
      subject.plugin(plugin.name, plugin.version).should eql(plugin)
    end
  end  
end
