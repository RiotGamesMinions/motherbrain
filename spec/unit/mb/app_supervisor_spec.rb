require 'spec_helper'

describe MB::AppSupervisor do
  subject { described_class }

  describe "::run!" do
    it "starts an actor called 'provisioner_manager'" do
      subject.run!

      Celluloid::Actor[:provisioner_manager].should_not be_nil
    end
  end
end
