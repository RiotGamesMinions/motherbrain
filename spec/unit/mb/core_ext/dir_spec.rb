require 'spec_helper'

describe Dir do
  describe "#has_mb_plugin?" do
    let(:target) { tmp_path.join('some_directory') }
    subject { described_class.has_mb_plugin?(target) }

    context "when the directory does not exist" do
      before { FileUtils.rm_f(target) }
      it { should be_false }
    end

    context "when the directory exists" do
      before { FileUtils.mkdir_p(target) }

      before do
        described_class.stub(:has_mb_file?).with(target).and_return(true)
        described_class.stub(:has_chef_metadata?).with(target).and_return(true)
      end

      context "but does not contain a motherbrain file" do
        before { described_class.stub(:has_mb_file?).with(target).and_return(false) }
        it { should be_false }
      end

      context "but does not contain a Chef metadata file" do
        before { described_class.stub(:has_mb_file?).with(target).and_return(false) }
        it { should be_false }
      end

      context "and contains a motherbrain file and Chef metadata file" do
        it { should be_true }
      end
    end
  end

  describe "#has_mb_file?" do
    let(:target) { tmp_path.join('some_directory') }
    subject { described_class.has_mb_file?(target) }

    context "when the directory does not exist" do
      before { FileUtils.rm_f(target) }
      it { should be_false }
    end

    context "when the directory exists" do
      before { FileUtils.mkdir_p(target) }

      context "but does not contain a motherbrain file" do
        before { FileUtils.rm_f(target.join(MB::Plugin::PLUGIN_FILENAME)) }
        it { should be_false }
      end

      context "and has a motherbrain file" do
        before { FileUtils.touch(target.join(MB::Plugin::PLUGIN_FILENAME)) }
        it { should be_true }
      end
    end
  end

  describe "#has_chef_metadata?" do
    let(:target) { tmp_path.join('some_directory') }
    subject { described_class.has_chef_metadata?(target) }

    context "when the directory does not exist" do
      before { FileUtils.rm_f(target) }
      it { should be_false }
    end

    context "when the directory exists" do
      before { FileUtils.mkdir_p(target) }

      context "but does not contain a Chef JSON or Ruby metadata file" do
        before do
          FileUtils.rm_f(target.join(MB::Plugin::RUBY_METADATA_FILENAME))
          FileUtils.rm_f(target.join(MB::Plugin::JSON_METADATA_FILENAME))
        end
        it { should be_false }
      end

      context "and contains a Chef JSON metadata file" do
        before { FileUtils.touch(target.join(MB::Plugin::JSON_METADATA_FILENAME)) }
        it { should be_true }
      end

      context "and contains a Chef Ruby metadata file" do
        before { FileUtils.touch(target.join(MB::Plugin::RUBY_METADATA_FILENAME)) }
        it { should be_true }
      end
    end
  end
end
