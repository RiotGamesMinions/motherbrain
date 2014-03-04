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

  describe MB::Berkshelf::Lockfile do
    describe "#locked_versions" do

      let(:plugin_path) { '/foo' }
      subject { MB::Berkshelf::Lockfile.from_path(plugin_path) }

      context "when there is no lockfile present" do
        its(:locked_versions) { should == {} }
      end

      context "when there is a lockfile present" do
        let(:plugin_path) { fixtures_path.join('myface-0.1.0') }
        its(:locked_versions) { should == {'cookbook1' => '2.0.1', 'cookbook2' => '1.0.13'}}
      end
    end
  end
end
