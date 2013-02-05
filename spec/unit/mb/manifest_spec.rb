require 'spec_helper'

describe MB::Manifest do
  subject { manifest }
  let(:manifest) { described_class.new(attributes) }

  let(:valid_json) do
    <<-JSON
      {
        "nodes": [
          {
            "type": "m1.large",
            "components": ["activemq::master"]
          },
          {
            "type": "m1.large",
            "count": 2,
            "components": ["activemq::slave"]
          },
          {
            "type": "m1.small",
            "components": ["nginx::master"]
          }
        ]
      }
    JSON
  end

  let(:valid_hash) {
    {
      nodes: [
        {
          type: "m1.large",
          components: ["activemq::master"]
        },
        {
          type: "m1.large",
          count: 2,
          components: ["activemq::slave"]
        },
        {
          type: "m1.small",
          components: ["nginx::master"]
        }
      ]
    }
  }

  let(:attributes) { valid_hash }

  it { should == valid_hash }
  it { should have_key(:nodes) }

  context "with an empty hash" do
    let(:attributes) { Hash.new }

    it { should be_empty }
  end

  describe "#[:nodes]" do
    subject { manifest[:nodes] }

    it { should have(3).items }
    it { should =~ valid_hash[:nodes] }
  end

  describe ".from_file" do
    pending
  end

  describe ".from_json" do
    pending
  end

  describe "#from_json" do
    subject { from_json }
    let(:from_json) { described_class.new.from_json(json) }

    let(:json) { valid_json }

    it { should == valid_hash }

    context "given an empty json string" do
      let(:json) { "{}" }

      it { should be_empty }
    end

    context "given an invalid JSON string" do
      let(:json) { "sdf" }

      it "raises" do
        expect {
          from_json
        }.to raise_error(MB::InvalidJSONManifest)
      end
    end
  end

  describe "#save" do
    pending
  end
end
