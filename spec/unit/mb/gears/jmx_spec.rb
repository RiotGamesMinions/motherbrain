require 'spec_helper'

if jruby?
  describe MB::Gear::JMX do
    subject { described_class }

    it "is registered with MB::Gear" do
      MB::Gear.all.should include(subject)
    end

    it "has the inferred keyword ':jmx' from it's Class name" do
      subject.keyword.should eql(:jmx)
    end

    describe "#action" do
      subject { MB::Gear::JMX.new(@context) }

      it "returns a Gear::JMX::Action" do
        subject.action(9001, "com.some.thing:name=thing") do |mbean|
        end.should be_a(MB::Gear::JMX::Action)
      end
    end
  end
end
