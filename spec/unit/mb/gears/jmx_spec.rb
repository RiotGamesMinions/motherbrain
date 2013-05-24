require 'spec_helper'

describe MB::Gear::JMX do
  subject { described_class }

  it "is registered with MB::Gear" do
    MB::Gear.all.should include(subject)
  end

  it "has the inferred keyword ':jmx' from it's Class name" do
    subject.keyword.should eql(:jmx)
  end

  describe "#action" do
    subject { MB::Gear::JMX.new }
    before { described_class.any_instance.stub(jruby?: true) }

    it "returns a Gear::JMX::Action" do
      expect(subject.action(9001, "com.some.thing:name=thing") { |bean| }).to be_a(MB::Gear::JMX::Action)
    end

    context "when not running under JRuby" do
      before { described_class.any_instance.stub(jruby?: false) }

      it "raises an ActionNotSupported error" do
        expect {
          subject.action(9001, "com.some.thing:name=thing")
        }.to raise_error(MB::ActionNotSupported)
      end
    end
  end
end
