require 'spec_helper'
require 'timecop'

describe MB::Mutex do
  subject { mutex }

  let(:klass) { described_class }
  let(:mutex) { klass.new name, chef_connection_stub }

  let(:client_name) { "johndoe" }
  let(:name) { "my_lock" }
  let(:time) { Time.parse "2012-01-01 00:00" }

  let(:chef_connection_stub) { stub client_name: client_name }
  let(:locks_stub) { stub(
      delete: true,
      find: nil,
      new: stub(save: true)
  ) }

  before do
    Timecop.freeze time

    mutex.stub locks: locks_stub
  end

  its(:name) { should == name }

  describe "#lock" do
    subject(:lock) { mutex.lock }

    it "attempts a lock" do
      mutex.should_receive :attempt_lock

      lock
    end

    context "with no existing lock" do
      before { mutex.stub read: false, write: true }

      it { should be_true }

      context "and the lock attempt fails" do
        before { mutex.stub write: false }

        it { should be_false }
      end
    end

    context "with an existing lock" do
      before { mutex.stub read: {} }

      it { should be_false }
    end
  end

  describe "#unlock" do
    subject(:unlock) { mutex.unlock }

    it "attempts an unlock" do
      mutex.should_receive :attempt_unlock

      unlock
    end
  end

  describe "#attempt_lock" do
    subject(:attempt_lock) { mutex.attempt_lock }

    context "with no lock" do
      before do
        mutex.stub read: false, write: true
      end

      it { should be_true }

      it "creates a lock" do
        mutex.should_receive :write

        attempt_lock
      end
    end

    context "with an existing lock by us" do
      before do
        mutex.stub read: { "client_name" => client_name }
      end

      it { should be_true }

      it "does not try to create another lock" do
        mutex.should_not_receive :write

        attempt_lock
      end
    end

    context "with an existing lock by someone else" do
      before do
        mutex.stub read: { "client_name" => client_name.reverse }
      end

      it { should be_false }

      it "does not try to create another lock" do
        mutex.should_not_receive :write

        attempt_lock
      end
    end
  end

  describe "#attempt_unlock" do
    subject(:attempt_unlock) { mutex.attempt_unlock }

    context "with no lock" do
      before do
        mutex.stub :read
      end

      it { should be_false }

      it "does not delete the lock" do
        mutex.should_not_receive :delete

        attempt_unlock
      end
    end

    context "with an existing lock by us" do
      before do
        mutex.stub delete: true
        mutex.stub read: { "client_name" => client_name }
      end

      it { should be_true }

      it "deletes the lock" do
        mutex.should_receive :delete

        attempt_unlock
      end
    end

    context "with an existing lock by someone else" do
      before do
        mutex.stub read: { "client_name" => client_name.reverse }
      end

      it { should be_false }

      it "does not delete the lock" do
        mutex.should_not_receive :delete

        attempt_unlock
      end
    end
  end

  describe "#delete" do
    subject(:delete) { mutex.delete }

    it "deletes the data bag item" do
      locks_stub.should_receive :delete
      mutex.stub locks: locks_stub

      delete
    end

    context "with no locks data bag" do
      before { mutex.stub locks: nil }

      it { should be_true }
    end
  end

  describe "#write" do
    subject(:write) { mutex.write }

    before do
    end

    it "ensures that the data bag exists" do
      mutex.should_receive :ensure_data_bag_exists

      write
    end
  end
end
