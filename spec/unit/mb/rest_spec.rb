require 'spec_helper'

describe MB::REST do
  describe "::gateway" do
    it "raises a DeadActorError if a REST gateway is not started" do
      expect {
        subject.gateway
      }.to raise_error(Celluloid::DeadActorError)
    end
  end
end
