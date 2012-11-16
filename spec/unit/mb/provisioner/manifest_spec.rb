require 'spec_helper'

describe MB::Provisioner::Manifest do
  let(:valid_manifest) do
    {
      "m1.large" => {
        "activemq::master" => 1,
        "activemq::slave" => 2
      },
      "m1.small" => {
        "nginx::master" => 1
      }
    }
  end
  
  describe "ClassMethods" do
    subject { described_class }

    describe "::validate" do
      it "returns true given a hash in the proper format" do
        subject.validate(valid_manifest).should be_true
      end

      it "accepts a Provisioner::Manifest" do
        subject.validate(described_class.new).should be_true
      end

      it "raises InvalidProvisionManifest if given a non-hash value" do
        expect {
          subject.validate(1)
        }.to raise_error(MB::InvalidProvisionManifest)
      end
    end
  end
end
