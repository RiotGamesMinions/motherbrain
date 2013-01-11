require 'spec_helper'

describe MB::AuthSecret do
  describe "ClassMethods" do
    describe "::generate" do
      subject { described_class.generate }

      it "returns a new AuthSecret" do
        subject.should be_a(MB::AuthSecret)
      end
    end

    describe "::from_string" do
      let(:auth_key) { "some_key" }
      subject { described_class.from_string(auth_key) }

      it "returns an AuthSecret" do
        subject.should be_a(MB::AuthSecret)
      end
    end
  end

  describe "#key" do
    it "returns a string" do
      subject.key.should be_a(String)
    end
  end

  describe "#to_s" do
    it "is an alias for #key" do
      subject.to_s.should eql(subject.key)
    end
  end
end
