require 'spec_helper'

describe MB::JobManager do
  let(:fake_job) do
    Class.new do
      include Celluloid

      attr_reader :id

      def initialize
        @id = 1
      end
    end
  end

  before(:each) { @fake_job = fake_job.new }
  after(:each) { @fake_job.terminate if @fake_job.alive? }

  describe "#add" do
    it "adds a job to the jobs list" do
      subject.add(@fake_job)

      subject.jobs.should have(1).item
      subject.jobs.should include(@fake_job)
    end

    it "monitors the given job" do
      subject.add(@fake_job)

      subject.should be_monitoring(@fake_job)
    end
  end

  describe "#find" do
    it "returns a job of the given ID" do
      subject.add(@fake_job)

      subject.find(@fake_job.id).should eql(@fake_job)
    end

    it "returns nil if a job of the given ID is not found" do
      subject.find(@fake_job.id).should be_nil
    end
  end

  describe "#remove" do
    before(:each) do
      subject.add(@fake_job)
      subject.remove(@fake_job)
    end

    it "removes the given job from the job list" do
      subject.jobs.should have(0).items
    end

    it "should not be monitoring the removed job" do
      subject.should_not be_monitoring(@fake_job)
    end
  end
end
