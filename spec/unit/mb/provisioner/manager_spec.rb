require 'spec_helper'

describe MB::Provisioner::Manager do
  subject { provisioner_manager }

  let(:provisioner_manager) { described_class.new }

  let(:job) { double(MB::Job, alive?: true) }
  let(:environment) { "production" }
  let(:manifest) { double(MB::Manifest, to_hash: { 'a' => 1 }, provisioner: nil, options: nil) }
  let(:plugin) { double(MB::Plugin, name: "MyPlugin") }

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
    let(:job) { MB::Job.new(:provision) }
    let(:options) { Hash.new }

    let(:bootstrapper) { double('bootstrapper') }
    let(:default_provisioner) { provisioner_manager.provisioner_registry[MB::Provisioner.default_id] }

    subject(:provision) do
      @ticket = job.ticket
      provisioner_manager.stub(bootstrapper: bootstrapper)
      provisioner_manager.provision(job, environment, manifest, plugin, options)
    end

    context "when the manifest defines a provisioner that is started and registered" do
      before { manifest.stub(provisioner: MB::Provisioner.default_id) }

      it "successfully provisions and bootstraps" do
        response           = double('provision-response')
        bootstrap_manifest = double('bootstrap-manifest')

        manifest.should_receive(:validate!).with(plugin)
        default_provisioner.should_receive(:up).with(job, environment, manifest, plugin, anything).and_return(response)
        MB::Bootstrap::Manifest.should_receive(:from_provisioner).with(response, manifest).
          and_return(bootstrap_manifest)

        provisioner_manager.should_receive(:write_bootstrap_manifest)
        bootstrapper.should_receive(:bootstrap)

        provision
        expect(@ticket.state).to eql(:success)
      end
    end

    context "with skip_bootstrap: true" do
      before { options[:skip_bootstrap] = true }

      it "successfully provisions but skips bootstrap" do
        response = double('provision-response')

        manifest.should_receive(:validate!).with(plugin)
        default_provisioner.should_receive(:up).with(job, environment, manifest, plugin, anything).and_return(response)

        bootstrapper.should_not_receive(:bootstrap)

        provision
        expect(@ticket.state).to eql(:success)
      end
    end
  end

  describe "#write_bootstrap_manifest" do
    subject(:write_bootstrap_manifest) do
      provisioner_manager.send(:write_bootstrap_manifest, job, environment, manifest, plugin)
    end

    it "writes the manifest" do
      job.should_receive :set_status

      expect {
        write_bootstrap_manifest
      }.to change { MB::FileSystem.manifests.opendir.count }.by 1

      filename = MB::FileSystem.manifests.opendir.to_a.select { |filename|
        filename.end_with?(".json")
      }.last

      expect(filename).to include(plugin.name)
      expect(filename).to include(environment)

      contents = File.read(MB::FileSystem.manifests.join(filename))

      expect(JSON.parse(contents)).to eq(manifest.to_hash)
    end
  end

  describe "#choose_provisioner" do
    let(:id) { nil }
    let(:provisioner) { subject.choose_provisioner(id) }

    context "when the given id is nil" do
      let(:id) { nil }

      it "returns the running default provisioner" do
        expect(provisioner).to be_a(MB::Provisioner.default)
      end
    end

    context "when the given id matches a registered provisioner" do
      let(:id) { :aws }

      it "returns the matching running provisioner" do
        expect(provisioner).to be_a(MB::Provisioner::AWS)
      end
    end

    context "when there is no provisioner registered with the given id" do
      let(:id) { :not_existent }

      it "raises ProvisionerNotRegistered if a provisioner with the given ID has not been registered" do
        expect { provisioner }.to raise_error(MB::ProvisionerNotStarted)
      end
    end
  end
end
