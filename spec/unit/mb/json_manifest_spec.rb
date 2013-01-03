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
      it "assigns the given attributes to self" do
        attributes = { "m1.large" => { "activemq::master" => 1 } }

        subject.new(attributes).should eql(attributes)
      end

      it "has a key for each key in the json" do
        parsed = subject.new(valid_hash)

        parsed.should have(2).items
        parsed.should have_key("m1.large")
        parsed.should have_key("m1.small")
      end

      context "given an empty hash" do
        it "returns an empty Manifest" do
          subject.new(Hash.new).should be_empty
        end
      end
    end

    describe "::from_file" do
      pending
    end

    describe "::from_json" do
      pending
    end
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
        }.to raise_error(MB::InvalidJSONManifest)
      end
    end
  end

  describe "#save" do
    pending
  end
end
