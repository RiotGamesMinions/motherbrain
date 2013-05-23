require 'spec_helper'

if jruby?
  describe MB::Gear::Jmx do

    describe "Class" do
      subject { MB::Gear::Jmx }

      it "is registered with MB::Gear" do
        MB::Gear.all.should include(subject)
      end

      it "has the inferred keyword ':jmx' from it's Class name" do
        subject.keyword.should eql(:jmx)
      end
    end

    describe "#action" do
      subject { MB::Gear::Jmx.new(@context) }

      it "returns a Gear::Jmx::Action" do
        subject.action(9001, "com.some.thing:name=thing") do |mbean|
        end.should be_a(MB::Gear::Jmx::Action)
      end
    end
  end
end
