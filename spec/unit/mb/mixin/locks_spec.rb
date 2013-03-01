require 'spec_helper'

describe MB::Locks do
  describe "ClassMethods" do
    subject { described_class }

    describe "::manager" do
      it "returns a Locks::Manager" do
        subject.manager.should be_a(MB::Locks::Manager)
      end
    end
  end

  subject do
    Class.new do
      include MB::Locks
    end.new
  end

  before(:each) { MB::Locks.manager.reset! }

  describe "#chef_locks" do
    it "returns a Set" do
      subject.chef_locks.should be_a(Set)
    end
  end

  describe "#find_lock" do
    it "returns a Chef::Mutex if a mutex with the given name is registered" do
      mutex = double('mutex', type: :chef_environment, name: "my_environment")
      MB::Locks.manager.stub(:locks).and_return([mutex])

      subject.find_lock(chef_environment: "my_environment").should eql(mutex)
    end

    it "returns nil if a mutex with the given name is not registered" do
      subject.find_lock(chef_environment: "not-there-lock").should be_nil
    end
  end
end
