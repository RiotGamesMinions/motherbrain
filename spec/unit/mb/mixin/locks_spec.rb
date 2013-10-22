require 'spec_helper'

describe MB::Mixin::Locks do
  subject do
    Class.new do
      include MB::Mixin::Locks
    end.new
  end

  let(:lock_manager) { MB::LockManager.instance }

  before(:each) { lock_manager.reset }

  describe "#chef_locks" do
    it "returns a Set" do
      subject.chef_locks.should be_a(Set)
    end
  end

  describe "#find_lock" do
    it "returns a Chef::Mutex if a mutex with the given name is registered" do
      mutex = double('mutex', type: :chef_environment, name: "my_environment")
      lock_manager.stub(:locks).and_return([mutex])

      subject.find_lock(chef_environment: "my_environment").should eql(mutex)
    end

    it "returns nil if a mutex with the given name is not registered" do
      subject.find_lock(chef_environment: "not-there-lock").should be_nil
    end
  end
end
