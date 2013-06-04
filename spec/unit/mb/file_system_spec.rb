require 'spec_helper'

describe MB::FileSystem do
  describe ".init" do
    subject(:init) { described_class.init }

    it "creates the directory structure" do
      FileUtils.should_receive(:mkdir_p).exactly(5).times

      init
    end
  end

  describe ".logs" do
    subject(:logs) { described_class.logs }

    it { should be_a(Pathname) }

    it "is a path within the root of the motherbrain filesystem" do
      expect(logs.to_s).to include(MB::FileSystem.root.to_s)
    end
  end

  describe ".manifests" do
    subject(:manifests) { described_class.manifests }

    it { should be_a(Pathname) }

    it "is a path within the root of the motherbrain filesystem" do
      expect(manifests.to_s).to include(MB::FileSystem.root.to_s)
    end
  end

  describe ".root" do
    subject(:root) { described_class.root }

    it { should be_a(Pathname) }
  end

  describe ".tmp" do
    subject(:tmp) { described_class.tmp }

    it { should be_a(Pathname) }

    it "is a path within the root of the motherbrain filesystem" do
      expect(tmp.to_s).to include(MB::FileSystem.root.to_s)
    end
  end

  describe ".tmpdir" do
    subject(:tmpdir) { described_class.tmpdir }

    it { should be_a(String) }

    it "creates a temporary directory in the motherbrain temp filesystem" do
      expect(tmpdir).to include(MB::FileSystem.tmp.to_s)
    end

    context "when given a prefix" do
      subject(:tmpdir) { described_class.tmpdir(prefix) }

      let(:prefix) { "test" }

      it "creates a directory with that prefix" do
        expect(tmpdir.split(?/).last).to be_start_with(prefix)
      end
    end
  end
end
