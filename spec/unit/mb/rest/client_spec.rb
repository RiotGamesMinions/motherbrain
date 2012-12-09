require 'spec_helper'

describe MB::REST::Client do
  before(:all) do
    WebMock.disable!
    @gateway = MB::REST::Gateway.new
  end

  after(:all) { @gateway.terminate }

  subject { described_class.new }

  describe "#config" do
    it "returns an instance of MB::Config" do
      subject.config.should be_a(MB::Config)
    end
  end
end
