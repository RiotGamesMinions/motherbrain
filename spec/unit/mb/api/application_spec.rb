require 'spec_helper'

describe MB::API::Application do
  subject { described_class }

  it "has V1 mounted at '/'" do
    endpoint = subject.endpoints.find { |endpoint| endpoint.options[:app] == MB::API::V1 }
    expect(endpoint).to_not be_nil
    expect(endpoint.options[:path]).to include('/')
  end
end
