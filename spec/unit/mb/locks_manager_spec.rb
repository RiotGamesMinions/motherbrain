require 'spec_helper'

describe MB::LockManager do
  subject { described_class.new }

  describe "#locks" do
    it "returns a Set" do
      subject.locks.should be_a(Set)
    end
  end

  describe "#find" do
    it "returns a Chef::Mutex if a mutex is registered" do
      mutex = double('mutex', type: :chef_environment, name: "my_environment")
      subject.stub(:locks).and_return([mutex])

      subject.find(chef_environment: "my_environment").should eql(mutex)
    end

    it "returns nil if a mutex with the given name is not registered" do
      subject.find(chef_environment: "not-there-lock").should be_nil
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

  describe "#lock" do
    let(:environment) { "rspec-test" }
    let(:job) { MB::Job.new(:lock) }

    it "creates a new ChefMutex and locks it" do
      mutex = double('mutex')
      mutex.should_receive(:lock)
      MB::ChefMutex.should_receive(:new).and_return(mutex)

      subject.lock(job, environment)
    end
  end

  describe "#async_lock" do
    let(:environment) { "rspec-test" }

    it "returns a JobRecord" do
      expect(subject.async_lock(environment)).to be_a(MB::JobRecord)
    end
  end

  describe "unlock" do
    let(:environment) { "rspec-test" }
    let(:job) { MB::Job.new(:unlock) }

    it "creates a new ChefMutex and unlocks it" do
      mutex = double('mutex')
      mutex.should_receive(:unlock)
      MB::ChefMutex.should_receive(:new).and_return(mutex)

      subject.unlock(job, environment)
    end
  end

  describe "#async_unlock" do
    let(:environment) { "rspec-test" }

    it "returns a JobRecord" do
      expect(subject.async_unlock(environment)).to be_a(MB::JobRecord)
    end
  end
end
