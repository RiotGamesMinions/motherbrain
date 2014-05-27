require 'spec_helper'

describe MB::Application do
  describe "ClassMethods" do
    subject { described_class }

    describe "::registry" do
      it "returns an instance of Celluloid::Registry" do
        subject.registry.should be_a(Celluloid::Registry)
      end
    end

    describe "::config" do
      it "returns an instance of MB::Config" do
        subject.config.should be_a(MB::Config)
      end
    end

    describe "::pause" do
      it "should pause" do
        subject.pause
        expect(subject.paused?).to eq(true)
      end
    end

    describe "::resume" do
      it "should resume" do
        subject.resume
        expect(subject.paused?).to eq(false)
      end
    end
  end
end
