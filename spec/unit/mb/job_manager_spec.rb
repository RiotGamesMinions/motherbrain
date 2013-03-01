require 'spec_helper'

describe MB::JobManager do
  let(:fake_job) do
    Class.new do
      include Celluloid

      attr_reader :id, :type, :state, :status, :result
      attr_reader :time_start, :time_end

      @id = 1
      @type = 'fake'
      @state = :pending
      @status = ""
      @result = nil
    end
  end

  before(:each) { @fake_job = fake_job.new }
  after(:each) { @fake_job.terminate if @fake_job.alive? }

  describe "#add" do
    it "adds a job to the active jobs list" do
      subject.add(@fake_job)

      subject.active.should have(1).item
      subject.active.should include(@fake_job)
    end

    it "monitors the given job" do
      subject.add(@fake_job)

      subject.should be_monitoring(@fake_job)
    end
  end

  describe "#find" do
    it "returns a record of the job" do
      subject.add(@fake_job)

      subject.find(@fake_job.id).should be_a(MB::JobRecord)
    end
  end

  describe "#complete_job" do
    before(:each) do
      subject.add(@fake_job)
      subject.complete_job(@fake_job)
    end

    it "removes the given job from the active job list" do
      subject.active.should have(0).items
    end

    it "should not be monitoring the removed job" do
      subject.should_not be_monitoring(@fake_job)
    end
  end

  describe "#active_jobs" do
    it "has the same jobs as the active jobs set" do
      subject.add(@fake_job)

      subject.active_jobs.should have(1).item
      subject.active_jobs[0].id.should == @fake_job.id
    end

    it "should be a JobRecord" do
      subject.add(@fake_job)

      subject.active_jobs[0].should be_an_instance_of(MotherBrain::JobRecord)
    end
  end


end
