require 'spec_helper'

describe MB::EnvironmentManager do
  subject { described_class.new }

  describe "#async_configure" do
    let(:environment) { "rspec-test" }
    let(:options) { Hash.new }

    it "asynchronously calls #configure and returns a JobRecord" do
      subject.should_receive(:async).with(:configure, kind_of(MB::Job), environment, options)

      subject.async_configure(environment, options).should be_a(MB::JobRecord)
    end
  end

  describe "#configure" do
    let(:job) { MB::Job.new(:environment_configure) }
    let(:env_id) { "rspec" }
    let(:options) { Hash.new }

    before { @record = job.ticket }

    context "when the environment exists" do
      pending
    end

    context "when the environment does not exist" do
      before { subject.stub_chain(:ridley, :environment, :find).with(env_id).and_return(nil) }

      it "sets the job to failure because of EnvironmentNotFound" do
        subject.configure(job, env_id, options)
        expect(@record).to be_failure
        expect(@record.result).to be_a(MB::EnvironmentNotFound)
      end
    end
  end

  describe "#find" do
    context "when the environment is not present on the remote Chef server" do
      let(:env_id) { "rspec" }

      before(:each) do
        MB::Application.ridley.stub_chain(:environment, :find).with(env_id).and_return(nil)
      end

      it "aborts an EnvironmentNotFound error" do
        expect { subject.find(env_id) }.to raise_error(MB::EnvironmentNotFound)
      end
    end
  end

  describe "#list" do
    pending
  end

  describe "#create" do
    let(:environment_name) { "rspec" }

    before do
      MB::Application.ridley.stub_chain(:environment, :create).
        with(name: environment_name).and_return(name: environment_name)
    end

    it "creates an environment" do
      subject.create(environment_name).should eq(name: environment_name)
    end
  end
end
