require 'spec_helper'

describe MB::Provisioner::Manager do
  describe "ClassMethods" do
    subject { described_class }

    describe "::choose_provisioner" do
      it "returns the default provisioner if nil is provided" do
        subject.choose_provisioner(nil).should eql(MB::Provisioners.default)
      end

      it "returns the provisioner corresponding to the given ID" do
        subject.choose_provisioner(:environment_factory).provisioner_id.should eql(:environment_factory)
      end

      it "raises ProvisionerNotRegistered if a provisioner with the given ID has not been registered" do
        expect {
          subject.choose_provisioner(:not_existant)
        }.to raise_error(MB::ProvisionerNotRegistered)
      end
    end
  end
end
