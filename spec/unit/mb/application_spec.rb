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
  end
end
