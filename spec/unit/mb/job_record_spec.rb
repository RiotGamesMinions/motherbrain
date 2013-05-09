require 'spec_helper'

describe MB::JobRecord do
  let(:job) do
    double('job',
      id: '123',
      type: 'bootstrap',
      state: 'pending',
      status: 'just starting',
      status_buffer: ['just starting'],
      result: 'finished',
      time_start: Time.now,
      time_end: Time.now
    )
  end

  describe "#to_hash" do
    subject { described_class.new(job).to_hash }

    it "has the 'id' of the given Job" do
      subject[:id].should eql(job.id)
    end

    it "has the 'type' of the given Job" do
      subject[:type].should eql(job.type)
    end

    it "has the 'state' of the given Job" do
      subject[:state].should eql(job.state)
    end

    it "has the 'status' of the given Job" do
      subject[:status].should eql(job.status)
    end

    it "has the 'result' of the given Job" do
      subject[:result].should eql(job.result)
    end

    it "has the 'time_start' of the given Job" do
      subject[:time_start].should eql(job.time_start)
    end

    it "has the 'time_end' of the given Job" do
      subject[:time_end].should eql(job.time_end)
    end
  end

  describe "#to_json" do
    subject { described_class.new(job).to_json }

    it { should have_json_path("id") }
    it { should have_json_path("type") }
    it { should have_json_path("state") }
    it { should have_json_path("status") }
    it { should have_json_path("result") }
    it { should have_json_path("time_start") }
    it { should have_json_path("time_end") }
  end
end
