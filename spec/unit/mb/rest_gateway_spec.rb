require 'spec_helper'

describe MB::RestGateway do
  include Rack::Test::Methods

  before(:all) { MB::RestGateway.start(port: 26101) }
  after(:all) { MB::RestGateway.stop }
  let(:app) { MB::RestGateway.instance.rack_app }

  describe "#rack_app" do
    it "returns MB::API::Application" do
      subject.rack_app.should be_a(MB::API::Application)
    end
  end
end
