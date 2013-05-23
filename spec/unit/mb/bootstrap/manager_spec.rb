require 'spec_helper'

describe MB::Bootstrap::Manager do
  subject { manager }
  let(:manager) { described_class.new }

  let(:cookbook_metadata) {
    MB::CookbookMetadata.from_file(fixtures_path.join('cb_metadata.rb'))
  }

  let(:plugin) {
    MB::Plugin.new(cookbook_metadata) do
      component "activemq" do
        group "master"
        group "slave"
      end

      component "nginx" do
        group "master"
      end

      stack_order do
        async do
          bootstrap("activemq::master")
          bootstrap("activemq::slave")
        end

        bootstrap("nginx::master")
      end
    end
  }

  let(:manifest) {
    MB::Bootstrap::Manifest.new({
      nodes: [
        {
          groups: ["activemq::master"],
          hosts: [
            "amq1.riotgames.com",
            "amq2.riotgames.com"
          ]
        },
        {
          groups: ["activemq::slave"],
          hosts: [
            "amqs1.riotgames.com",
            "amqs2.riotgames.com"
          ]
        },
        {
          groups: ["nginx::master"],
          hosts: [
            "nginx1.riotgames.com"
          ]
        }
      ]
    })
  }

  let(:environment) { "test" }
  let(:server_url) { MB::Application.config.chef.api_url }
  let(:job_stub) do
    stub(MB::Job, alive?: true, set_status: nil)
  end

  before do
    stub_request(:get, File.join(server_url, "nodes")).
      to_return(status: 200, body: {})
    stub_request(:get, File.join(server_url, "environments/test")).
      to_return(status: 200, body: {})

    manager.stub(async: manager)
  end

  describe "#async_bootstrap" do
    it "delegates asynchronously to {#bootstrap}" do
      options = double('options')
      manager.should_receive(:async).with(
        :bootstrap,
        kind_of(MB::Job),
        environment,
        manifest,
        plugin,
        options
      )

      manager.async_bootstrap(environment, manifest, plugin, options)
    end

    it "returns a JobRecord" do
      manager.async_bootstrap(environment, manifest, plugin).should be_a(MB::JobRecord)
    end
  end

  describe "#bootstrap" do
    let(:options) { Hash.new }

    before(:each) do
      job_stub.stub(set_status: nil, report_success: nil)
      job_stub.should_receive(:report_running)
      job_stub.should_receive(:terminate).once
      manager.stub(concurrent_bootstrap: [])
    end

    let(:run) { manager.bootstrap(job_stub, environment, manifest, plugin, options) }

    context "should validate that the required files and configuration are available prior to attempting to bootstrap" do
      it "and fail early if the validation pem is missing", focus: true do
        job_stub.stub(:report_failure)

        manager.should_receive(:assert_file_exists!).and_raise(MB::RequiredFileNotFound.new('/some/path'))
        manager.should_not_receive(:chef_synchronize)

        run
      end
    end

    context "when the environment cannot be found" do
      before(:each) do
        manager.stub_chain(:chef_connection, :environment, :find).with(environment).and_return(nil)
      end

      it "sets the job to failed" do
        job_stub.stub(alive?: true)
        job_stub.should_receive(:report_failure)

        run
      end
    end
    
    context "when the given bootstrap manifest is invalid" do
      it "sets the job to failed" do
        job_stub.should_receive(:report_failure)
        manifest.should_receive(:validate!).with(plugin).and_raise(MB::InvalidBootstrapManifest)

        run
      end
    end

    context "when :environment_attributes_file is passed as an option" do
      let(:filepath) { double }

      before do
        options[:environment_attributes_file] = filepath
      end

      it "sets environment attributes on the environment with the contents of the file" do
        manager.should_receive(:set_environment_attributes_from_file).with(environment, filepath)
        run
      end

      context "when the environment attributes file is invalid" do
        it "sets the job to failed" do
          manager.should_receive(:set_environment_attributes_from_file).and_raise(MB::InvalidAttributesFile)
          job_stub.should_receive(:report_failure)

          run
        end
      end
    end

    context "when :environment_attributes_file is not passed as an option" do
      before do
        options[:environment_attributes_file] = nil
      end

      it "does not set the environment attributes on the environment" do
        manager.should_not_receive(:set_environment_attributes_file)
        run
      end
    end
  end

  describe "#concurrent_bootstrap" do
    let(:concurrent_bootstrap) { manager.concurrent_bootstrap(job_stub, manifest, boot_tasks, options) }
    let(:boot_tasks) { 
      double('boot_task', 
        groups: nil,
        group_object: group_object_stub)
    }
    let(:group_object_stub) { double('group_object', run_list: nil, chef_attributes: nil) }
    let(:options) { Hash.new }
    let(:worker_stub) { double('worker', alive?: nil, future: double('future', value: nil)) }

    before do
      manifest.stub(:hosts_for_groups).and_return("amq1.riotgames.com")
      MB::Bootstrap::Worker.stub(:new).and_return(worker_stub)
      options.merge!(run_list: group_object_stub.run_list, attributes: group_object_stub.chef_attributes)
    end

    context "when there are no nodes in the manifest" do
      let(:log_stub) { double('log') }

      before do
        manifest.stub(:hosts_for_groups).and_return(Array.new)
        subject.stub(:log).and_return(log_stub)
      end

      it "logs a message that this boot_task will be skipped" do
        log_stub.should_receive(:info)
        concurrent_bootstrap
      end
    end

    context "when the manifest has no :options" do
      it "calls :run on the future with options" do
        worker_stub.should_receive(:future).with(:run, options)
        concurrent_bootstrap
      end
    end
  end
end
