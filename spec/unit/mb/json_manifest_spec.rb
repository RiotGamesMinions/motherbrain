require 'spec_helper'

describe MB::JSONManifest do
  let(:valid_json) do
    <<-JSON
{
  "m1.large": {
    "activemq::master": 1,
    "activemq::slave": 2
  },
  "m1.small": {
    "nginx::master": 1
  }
}
JSON
  end

  let(:valid_hash) do
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

    describe "::new" do
      it "assigns the given path to the path attribute" do
        subject.new('/tmp/path').path.should eql('/tmp/path')
      end

      it "assigns the given attributes to self" do
        attributes = { "m1.large" => { "activemq::master" => 1 } }

        subject.new(nil, attributes).should eql(attributes)
      end
    end

    describe "::validate" do
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

  describe "#from_json" do
    it "returns self" do
      subject.from_json(valid_json).should eql(subject)
    end

    it "has a key for each key in the json" do
      parsed = subject.from_json(valid_json)

      parsed.should have(2).items
      parsed.should have_key("m1.large")
      parsed.should have_key("m1.small")
    end

    context "given an empty json string" do
      it "returns an empty Manifest" do
        subject.from_json("{}").should be_empty
      end
    end

    context "given an invalid JSON string" do
      it "raises" do
        expect {
          subject.from_json("sdf")
        }.to raise_error(MB::InvalidProvisionManifest)
      end
    end
  end

  describe "#from_hash" do
    it "returns self" do
      subject.from_hash(valid_hash).should eql(subject)
    end

    it "has a key for each key in the json" do
      parsed = subject.from_hash(valid_hash)

      parsed.should have(2).items
      parsed.should have_key("m1.large")
      parsed.should have_key("m1.small")
    end

    context "given an empty hash" do
      it "returns an empty Manifest" do
        subject.from_hash(Hash.new).should be_empty
      end
    end
  end

  describe "#save" do
    pending
  end
end
