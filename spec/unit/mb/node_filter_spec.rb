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

  subject { MB::NodeFilter.new(filter) }
  let(:filtered) { subject.filter(nodes) }
  let(:filter) {[]}

  describe "#ipaddress?" do
    it "should work" do
       expect(subject.ipaddress?("192.168.1.1")).to be_true
       expect(subject.ipaddress?("poop")).to be_false
       expect(subject.ipaddress?("192.168.1.3-5")).to be_false
    end
  end

  describe "#iprange" do
    it "should also work" do
      expect(subject.iprange("192.168.1.1-2")).to eq(["192.168.1.1", "192.168.1.2"])
      expect(subject.iprange("192.168.1.1")).to be_nil
      expect(subject.iprange("poop")).to be_nil
    end
  end

  describe "#filter" do
    context "when an ipaddress range is given" do
      let(:filter) { ["192.168.1.3-5"] }

      it "filters the nodes good" do
        expect(filtered.collect(&:public_ipv4)).to eq(["192.168.1.3", "192.168.1.4", "192.168.1.5"])
      end
    end

    context "when a full hostname is given" do
      let(:filter) { ["node2.test.riotgames.com"] }

      it "filters the nodes by their hostname" do
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
