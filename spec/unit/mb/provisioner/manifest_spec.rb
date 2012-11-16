require 'spec_helper'

describe MB::Provisioner::Manifest do
  describe "ClassMethods" do
    subject { described_class }

    describe "::validate" do
      it "returns true given a hash in the proper format" do
        subject.validate(Hash.new).should be_true
      end

      it "raises InvalidProvisionManifest if given a non-hash value" do
        expect {
          subject.validate(1)
        }.to raise_error(MB::InvalidProvisionManifest)
      end
    end

    describe "::from_file" do
      pending
    end
  end

  describe "#path" do
    it { subject.path.should be_a(String) }
  end
end
