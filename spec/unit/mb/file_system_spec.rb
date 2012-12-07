require 'spec_helper'

describe MB::FileSystem do
  subject { described_class }

  describe "::root" do
    it "returns a pathname" do
      subject.root.should be_a(Pathname)
    end
  end

  describe "::tmp" do
    it "returns a pathname" do
      subject.tmp.should be_a(Pathname)
    end
  end

  describe "::plugins" do
    it "returns a pathname" do
      subject.plugins.should be_a(Pathname)
    end
  end

  describe "::tmpdir" do
    it "returns a string" do
      subject.tmpdir.should be_a(String)
    end
  end
end
