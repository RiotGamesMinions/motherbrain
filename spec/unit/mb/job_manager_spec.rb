require 'spec_helper'

describe MB::JobManager do
  let(:fake_job) do
    Class.new do
      include Celluloid

      attr_reader :id, :type, :state, :status, :status_buffer, :result
      attr_reader :time_start, :time_end

      @id = 1
      @type = 'fake'
      @state = :pending
      @status = ""
      @status_buffer = [""]
      @result = nil
    end
  end

  before(:each) { @fake_job = fake_job.new }

  describe "#add" do
    it "adds a job to the active jobs list" do
      subject.add(@fake_job)

      subject.active.should have(1).item
      subject.active[0].id.should == @fake_job.id
      subject.active[0].should be_a(MB::JobRecord)
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
end
