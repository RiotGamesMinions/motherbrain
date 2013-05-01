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

    describe "::new_provisioner" do
      context ":with option set" do
        let(:options) { {with: "magic"} }

        it "should choose the 'magic' provisioner" do
          subject.should_receive(:choose_provisioner).with("magic").and_return(MB::Provisioners.default)
          subject.new_provisioner(options)
        end
      end
    end

    context ":with option not set" do
      let(:options) { Hash.new }

      it "should choose the default provisioner" do
        subject.should_receive(:choose_provisioner).with(nil).and_call_original
        subject.new_provisioner(options)
      end
    end
  end

  subject { described_class.new }

  describe "#async_provision" do
    let(:environment) { double('environment') }
    let(:manifest) { double('manifest') }
    let(:plugin) { double('plugin') }

    it "delegates asynchronously to {#provision}" do
      subject.should_receive(:async).with(
        :provision,
        kind_of(MB::Job),
        environment,
        manifest,
        plugin,
        anything()
      )

      subject.async_provision(environment, manifest, plugin)
    end

    it "returns a JobRecord" do
      subject.async_provision(environment, manifest, plugin).should be_a(MB::JobRecord)
    end
  end
end
