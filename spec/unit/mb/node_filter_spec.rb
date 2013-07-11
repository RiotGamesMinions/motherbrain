require 'spec_helper'

describe MB::NodeFilter do
  let(:nodes) do
    (1..10).to_a.collect do |i|
      double("node#{i}").tap do |d|
        d.stub(:public_hostname).and_return("node#{i}.test.riotgames.com")
        d.stub(:public_ipv4).and_return("192.168.1.#{i}")
      end
    end
  end

  describe "ClassMethods" do
    describe "::filter" do
      let(:segments) { [["192.168.1.3-5"]] }
      subject(:filter) { described_class.filter(segments, nodes) }

      context "given an array of arrays of segments" do
        it "returns the correct number of nodes" do
          expect(filter).to have(3).items
        end
      end
    end
  end

  subject { MB::NodeFilter.new(filter) }
  let(:filtered) { subject.filter(nodes) }
  let(:filter) {[]}

  describe ":expand_iprange" do
    let(:expand_ipranges) { described_class.expand_ipranges(nodes) }
    let(:nodes) { ["192.168.0.2", "192.168.0.5-8"] }

    it "expands any ipranges" do
      expect(expand_ipranges).to eq(["192.168.0.2", "192.168.0.5", "192.168.0.6", "192.168.0.7", "192.168.0.8"])
    end
  end

  describe "#ipaddress?" do
    it "is true for valid ipaddresses" do
       expect(subject.ipaddress?("192.168.1.1")).to be_true
    end

    it "is false for invalid ipaddresses" do
      expect(subject.ipaddress?("invalid")).to be_false
      expect(subject.ipaddress?("192.168.1.3-5")).to be_false
    end
  end

  describe "#iprange" do
    it "expands the range" do
      expect(subject.iprange("192.168.1.1-2")).to eq(["192.168.1.1", "192.168.1.2"])
    end

    it "is nil when not an iprange" do
      expect(subject.iprange("192.168.1.1")).to be_nil
      expect(subject.iprange("invalid")).to be_nil
    end
  end

  describe "#filter" do
    context "when an ipaddress range is given" do
      let(:filter) { ["192.168.1.3-5"] }

      it "filters the nodes" do
        expect(filtered.collect(&:public_ipv4)).to eq(["192.168.1.3", "192.168.1.4", "192.168.1.5"])
      end
    end

    context "when a full hostname is given" do
      let(:filter) { ["node2.test.riotgames.com"] }

      it "filters the nodes by their full hostname" do
        expect(filtered.collect(&:public_hostname)).to eq(["node2.test.riotgames.com"])
      end
    end

    context "when just the hostname is given" do
      let(:filter) { ["node2"] }

      it "filters the nodes by their full hostname" do
        expect(filtered.collect(&:public_hostname)).to eq(["node2.test.riotgames.com"])
      end
    end
  end
end
