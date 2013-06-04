require 'spec_helper'

describe MB::FileSystem do
  subject { described_class }

  describe "::logs" do
    it "returns a pathname" do
      subject.logs.should be_a(Pathname)
    end

    it "is a path within the root of the motherbrain filesystem" do
      subject.logs.to_s.should include(MB::FileSystem.root.to_s)
    end
  end

  describe "::manifests" do
    it "returns a pathname" do
      subject.manifests.should be_a(Pathname)
    end
  end

  describe "::root" do
    it "returns a pathname" do
      subject.root.should be_a(Pathname)
    end
  end

  describe "::tmp" do
    it "returns a pathname" do
      subject.tmp.should be_a(Pathname)
    end

    it "is a path within the root of the motherbrain filesystem" do
      subject.tmp.to_s.should include(MB::FileSystem.root.to_s)
    end
  end

  describe "::tmpdir" do
    it "returns a string" do
      subject.tmpdir.should be_a(String)
    end

    it "creates a temporary directory in the motherbrain temp filesystem" do
      subject.tmpdir.should include(MB::FileSystem.tmp.to_s)
    end
  end
end
