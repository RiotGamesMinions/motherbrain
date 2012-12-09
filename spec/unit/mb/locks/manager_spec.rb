require 'spec_helper'

describe MB::Locks::Manager do
  subject { described_class.new }

  describe "#locks" do
    it "returns a Set" do
      subject.locks.should be_a(Set)
    end
  end

  describe "#find" do
    it "returns a Chef::Mutex if a mutex with the given name is registered" do
      mutex = double('mutex', name: 'test-lock')
      subject.stub(:locks).and_return([mutex])

      subject.find("test-lock").should eql(mutex)
    end

    it "returns nil if a mutex with the given name is not registered" do
      subject.find("not-there-lock").should be_nil
    end
  end

  describe "#register_lock" do
    let(:mutex) { double('lock') }

    it "adds the given lock to the list of locks" do
      subject.register(mutex)

      subject.locks.should have(1).item
      subject.locks.should include(mutex)
    end
  end

  describe "#unregister_lock" do
    let(:mutex) { double('lock') }
    before(:each) { subject.register(mutex) }

    it "removes the given lock from the list of locks" do
      subject.unregister(mutex)

      subject.locks.should have(0).items
    end
  end
end
