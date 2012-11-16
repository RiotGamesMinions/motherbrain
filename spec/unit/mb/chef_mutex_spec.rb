require 'spec_helper'

describe MB::ChefMutex do
  subject { chef_mutex }

  let(:chef_mutex) { klass.new name, chef_connection_stub }

  let(:client_name) { "johndoe" }
  let(:name) { "my_lock" }

  let(:chef_connection_stub) { stub client_name: client_name }
  let(:locks_stub) { stub(
      delete: true,
      find: nil,
      new: stub(save: true)
  ) }

  before do
    chef_mutex.stub locks: locks_stub
    chef_mutex.stub externally_testing?: false
  end

  its(:name) { should == name }

  describe "#lock" do
    subject(:lock) { chef_mutex.lock options }

    let(:options) { Hash.new }

    it "attempts a lock" do
      chef_mutex.should_receive :attempt_lock

      lock
    end

    context "with no existing lock" do
      before { chef_mutex.stub read: false, write: true }

      it { should be_true }

      context "and the lock attempt fails" do
        before { chef_mutex.stub write: false }

        it { should be_false }
      end
    end

    context "with an existing lock" do
      before { chef_mutex.stub read: {}, write: true }

      it { should be_false }

      context "and passed force: true" do
        before do
          options[:force] = true
        end

        it { should be_true }
      end
    end
  end

  describe "#synchronize" do
    subject(:synchronize) { chef_mutex.synchronize options, &test_block }

    TestProbe = Object.new

    let(:options) { Hash.new }
    let(:test_block) { -> { TestProbe.testing } }

    before do
      chef_mutex.stub lock: true, unlock: true

      TestProbe.stub :testing
    end

    it "runs the block" do
      TestProbe.should_receive :testing

      synchronize
    end

    it "obtains a lock" do
      chef_mutex.should_receive :lock

      synchronize
    end

    it "releases the lock" do
      chef_mutex.should_receive :unlock

      synchronize
    end

    context "when the lock is unobtainable" do
      before do
        chef_mutex.stub lock: false, read: {}
      end

      it "does not attempt to release the lock" do
        chef_mutex.should_not_receive :unlock

        -> { synchronize }.should raise_error MB::ResourceLocked
      end

      it "raises a ResourceLocked error" do
        -> { synchronize }.should raise_error MB::ResourceLocked
      end

      context "and passed force: true" do
        before do
          options[:force] = true
        end

        it "locks with force: true" do
          chef_mutex.should_receive(:lock).with(force: true).and_return(true)

          synchronize
        end
      end
    end

    context "on block failure" do
      before do
        TestProbe.stub(:testing).and_raise(RuntimeError)
      end

      it "raises the error" do
        -> { synchronize }.should raise_error RuntimeError
      end

      it "releases the lock" do
        chef_mutex.should_receive :unlock

        -> { synchronize }.should raise_error RuntimeError
      end

      context "and passed unlock_on_failure: false" do
        before do
          options[:unlock_on_failure] = false
        end

        it "does not release the lock" do
          chef_mutex.should_not_receive :unlock

          -> { synchronize }.should raise_error RuntimeError
        end
      end
    end
  end

  describe "#unlock" do
    subject(:unlock) { chef_mutex.unlock }

    it "attempts an unlock" do
      chef_mutex.should_receive :attempt_unlock

      unlock
    end
  end

  describe "#attempt_lock" do
    subject(:attempt_lock) { chef_mutex.send :attempt_lock }

    context "with no lock" do
      before do
        chef_mutex.stub read: false, write: true
      end

      it { should be_true }

      it "creates a lock" do
        chef_mutex.should_receive :write

        attempt_lock
      end
    end

    context "with an existing lock by us" do
      before do
        chef_mutex.stub read: { "client_name" => client_name }
      end

      it { should be_true }

      it "does not try to create another lock" do
        chef_mutex.should_not_receive :write

        attempt_lock
      end
    end

    context "with an existing lock by someone else" do
      before do
        chef_mutex.stub read: { "client_name" => client_name.reverse }
      end

      it { should be_false }

      it "does not try to create another lock" do
        chef_mutex.should_not_receive :write

        attempt_lock
      end
    end
  end

  describe "#attempt_unlock" do
    subject(:attempt_unlock) { chef_mutex.send :attempt_unlock }

    context "with no lock" do
      before do
        chef_mutex.stub :read
      end

      it { should be_false }

      it "does not delete the lock" do
        chef_mutex.should_not_receive :delete

        attempt_unlock
      end
    end

    context "with an existing lock by us" do
      before do
        chef_mutex.stub delete: true
        chef_mutex.stub read: { "client_name" => client_name }
      end

      it { should be_true }

      it "deletes the lock" do
        chef_mutex.should_receive :delete

        attempt_unlock
      end
    end

    context "with an existing lock by someone else" do
      before do
        chef_mutex.stub read: { "client_name" => client_name.reverse }
      end

      it { should be_false }

      it "does not delete the lock" do
        chef_mutex.should_not_receive :delete

        attempt_unlock
      end
    end
  end

  describe "#delete" do
    subject(:delete) { chef_mutex.send :delete }

    it "deletes the data bag item" do
      locks_stub.should_receive :delete
      chef_mutex.stub locks: locks_stub

      delete
    end

    context "with no locks data bag" do
      before { chef_mutex.stub locks: nil }

      it { should be_true }
    end
  end

  describe "#write" do
    subject(:write) { chef_mutex.send :write }

    before do
      locks_stub.stub new: stub(save: nil, to_hash: nil)
    end

    it "ensures that the data bag exists" do
      chef_mutex.should_receive :ensure_data_bag_exists

      write
    end
  end
end
