require 'spec_helper'

describe MB::ApiClient::JobResource do
  subject { MB::ApiClient.new.job }

  describe "#active" do
    it "performs a GET request to /jobs/active.json" do
      stub_request(:get, "http://0.0.0.0:26100/jobs/active.json").to_return(status: 200)

      subject.active
    end
  end

  describe "#list" do
    it "performs a GET request to /jobs.json" do
      stub_request(:get, "http://0.0.0.0:26100/jobs.json").to_return(status: 200)

      subject.list
    end
  end

  describe "#show" do
    let(:job_id) { Celluloid::UUID.generate }

    it "performs a GET request to /jobs/{job_id}.json" do
      stub_request(:get, "http://0.0.0.0:26100/jobs/#{job_id}.json").to_return(status: 200)

      subject.show(job_id)
    end
  end
end
