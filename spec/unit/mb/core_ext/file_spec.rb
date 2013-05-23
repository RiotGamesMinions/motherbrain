require 'spec_helper'

describe File do
  describe "#is_chef_metadata?" do
    let(:filename) { 'metadata.rb' }
    let(:target) { tmp_path.join(filename) }
    subject { described_class.is_chef_metadata?(target) }

    context "when the file does not exist" do
      before { FileUtils.rm_f(target) }
      it { should be_false }
    end

    context "when the file exists" do
      before { FileUtils.touch(target) }

      context "and the basename matches the Chef Ruby metadata filename" do
        let(:filename) { MB::CookbookMetadata::RUBY_FILENAME }
        it { should be_true }
      end

      context "and the basename matches the Chef JSON metadata filename" do
        let(:filename) { MB::CookbookMetadata::JSON_FILENAME }
        it { should be_true }
      end

      context "and the basename does not match a Chef metadata filename" do
        let(:filename) { 'nothing.at.all' }
        it { should be_false }
      end
    end
  end

  describe "#is_mb_plugin?" do
    let(:filename) { 'motherbrain.rb' }
    let(:target) { tmp_path.join(filename) }
    subject { described_class.is_mb_plugin?(target) }

    context "when the file does not exist" do
      before { FileUtils.rm_f(target) }
      it { should be_false }
    end

    context "when the file exists" do
      before { FileUtils.touch(target) }

      context "and the basename matches a motherbrain plugin filename" do
        let(:filename) { MB::Plugin::PLUGIN_FILENAME }
        it { should be_true }
      end

      context "and the basename does not match a motherbrain plugin filename" do
        let(:filename) { 'something.not.real' }
        it { should be_false }
      end
    end
  end
end
