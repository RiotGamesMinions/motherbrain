require 'spec_helper'

describe MB::Provisioner::Manager do
  subject { provisioner_manager }

  let(:provisioner_manager) { described_class.new }

  let(:job) { double(MB::Job, alive?: true) }
  let(:environment) { "production" }
  let(:manifest) { double(MB::Manifest, as_json: { 'a' => 1 }, provisioner: "None") }
  let(:plugin) { double(MB::Plugin, name: "MyPlugin") }

  describe "ClassMethods" do
    subject { described_class }

    describe "::choose_provisioner" do
      it "returns the default provisioner if nil is provided" do
        subject.choose_provisioner(nil).should eql(MB::Provisioner.default)
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
          subject.should_receive(:choose_provisioner).with("magic").and_return(MB::Provisioner.default)
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

  describe "#provision" do
    subject(:provision) {
      provisioner_manager.provision(job, environment, manifest, plugin, options)
    }

    let(:options) { Hash.new }

    it "provisions and bootstraps" do
      worker_stub = double(MB::Provisioner)

      job.should_receive :report_running
      described_class.should_receive(:new_provisioner).and_return(worker_stub)
      MB::Provisioner::Manifest.should_receive :validate!

      worker_stub.should_receive :up

      bootstrap_manifest_stub = double(MB::Bootstrap::Manifest)

      MB::Bootstrap::Manifest.
        should_receive(:from_provisioner).
        and_return(bootstrap_manifest_stub)

      provisioner_manager.should_receive(:write_bootstrap_manifest)

      bootstrapper_stub = double(MB::Bootstrap::Manager)

      provisioner_manager.should_receive(:bootstrapper).and_return(bootstrapper_stub)

      bootstrapper_stub.should_receive :bootstrap

      job.should_receive :terminate

      job.should_not_receive :report_success

      provision
    end

    context "with skip_bootstrap: true" do
      let(:options) {
        { skip_bootstrap: true }
      }

      it "provisions but doesn't bootstrap" do
        worker_stub = double(MB::Provisioner)

        job.should_receive :report_running
        described_class.should_receive(:new_provisioner).and_return(worker_stub)
        MB::Provisioner::Manifest.should_receive :validate!

        worker_stub.should_receive :up

        job.should_receive :report_success

        provisioner_manager.should_not_receive :bootstrapper

        job.should_receive :terminate

        provision
      end
    end
  end

  describe "#write_bootstrap_manifest" do
    subject(:write_bootstrap_manifest) {
      provisioner_manager.send(:write_bootstrap_manifest,
        job, environment, manifest, plugin
      )
    }

    it "writes the manifest" do
      job.should_receive :set_status

      expect {
        write_bootstrap_manifest
      }.to change { MB::FileSystem.manifests.opendir.count }.by 1

      filename = MB::FileSystem.manifests.opendir.to_a.last

      expect(filename).to include(plugin.name)
      expect(filename).to include(environment)
      expect(filename).to be_end_with(".json")

      contents = File.read(MB::FileSystem.manifests.join(filename))

      expect(JSON.parse(contents)).to eq(manifest.as_json)
    end
  end
end
