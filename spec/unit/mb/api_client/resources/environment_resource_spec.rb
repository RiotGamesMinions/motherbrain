require 'spec_helper'

describe MB::ApiClient::EnvironmentResource do
  subject { MB::ApiClient.new.environment }

  describe "#destroy" do
    let(:env_id) { "rspec-environment" }
    
    it "returns decoded JSON from /environments.json" do
      stub_request(:delete, "http://0.0.0.0:1984/environments/#{env_id}.json").
        to_return(status: 200, body: MultiJson.encode({}))

      subject.destroy(env_id).should be_a(Hash)
    end
  end
end
