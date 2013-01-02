require 'spec_helper'

describe MB::ApiClient::JobResource do
  subject { MB::ApiClient.new.job }

  describe "#active" do
    it "returns decoded JSON from /jobs/active.json" do
      stub_request(:get, "http://0.0.0.0:1984/jobs/active.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.active.should be_a(Hash)
    end
  end

  describe "#list" do
    it "returns decoded JSON from /jobs.json" do
      stub_request(:get, "http://0.0.0.0:1984/jobs.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.list.should be_a(Hash)
    end
  end

  describe "#show" do
    let(:job_id) { Celluloid::UUID.generate }

    it "returns decoded JSON from /jobs/{job_id}.json" do
      stub_request(:get, "http://0.0.0.0:1984/jobs/#{job_id}.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.show(job_id).should be_a(Hash)
    end
  end
end
