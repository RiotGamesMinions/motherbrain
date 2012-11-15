require 'spec_helper'

describe MB::Application do
  subject { described_class }

  describe "::run!" do
    it "starts an actor and registers it as 'provisioner_manager'" do
      subject.run!

      Celluloid::Actor[:provisioner_manager].should_not be_nil
    end
  end
end
