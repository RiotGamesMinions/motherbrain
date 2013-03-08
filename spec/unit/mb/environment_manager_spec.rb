require 'spec_helper'

describe MB::EnvironmentManager do
  describe "#async_configure" do
    let(:environment) { "rspec-test" }
    let(:options) { Hash.new }

    it "asynchronously calls #configure and returns a JobRecord" do
      subject.should_receive(:async).with(:configure, kind_of(MB::Job), environment, options)

      subject.async_configure(environment, options).should be_a(MB::JobRecord)
    end
  end

  describe "#configure" do
    pending
  end
end
