require 'spec_helper'

describe MB::Berkshelf do
  describe "::cookbooks_path" do
    subject { described_class.cookbooks_path }

    it "returns a Pathname" do
      subject.should be_a(Pathname)
    end

    it "is in the Berkshelf path" do
      subject.to_s.should include(MB::Berkshelf.path.to_s)
    end
  end

  describe "::default_path" do
    subject { described_class.default_path }

    it "returns a String" do
      subject.should be_a(String)
    end

    it "returns the value of ENV['BERKSHELF_PATH'] if present" do
      target = "/tmp/berkshelf"
      ENV.stub(:[]).with("BERKSHELF_PATH").and_return(target)

      subject.should eql(target)
    end
  end

  describe "::path" do
    subject { described_class.path }

    it "returns a Pathname" do
      subject.should be_a(Pathname)
    end
  end
end
