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
    let(:job) { MB::Job.new(:bootstrap) }
    let(:options) { Hash.new }

    before(:each) do
      manager.stub(concurrent_bootstrap: {})
    end

    let(:run) { manager.bootstrap(job, environment, manifest, plugin, options) }

    context "when the validatiom key is not on disk" do
      it "fails the job before locking the environment" do
        config_manager.stub_chain(:config).and_return(chef: {validation_key: '/this/file/doesnt/exist.pem'})
        manager.should_not_receive(:chef_synchronize)
        job.should_receive(:report_failure)

        run
      end
    end

    context "when the environment cannot be found" do
      before(:each) do
        manager.stub_chain(:chef_connection, :environment, :find).with(environment).and_return(nil)
      end

      it "sets the job to failed before locking the environment" do
        manager.should_not_receive(:chef_synchronize)
        job.should_receive(:report_failure)

        run
      end
    end

    context "when the given bootstrap manifest is invalid" do
      it "sets the job to failed before locking the environment" do
        manifest.should_receive(:validate!).with(plugin).and_raise(MB::InvalidBootstrapManifest)
        manager.should_not_receive(:chef_synchronize)
        job.should_receive(:report_failure)

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
        it "sets the job to failed before running #concurrent_bootstrap" do
          manager.should_receive(:set_environment_attributes_from_file).and_raise(MB::InvalidAttributesFile)
          manager.should_not_receive(:concurrent_bootstrap)
          job.should_receive(:report_failure)

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

    context "when all nodes bootstrap successfully" do
      let(:host_one) { "euca-10-20-37-171.eucalyptus.cloud.riotgames.com" }
      let(:host_two) { "euca-10-20-37-172.eucalyptus.cloud.riotgames.com" }

      let(:response) do
        {
          host_one => {
            groups: ["activemq::master"],
            result: {
              status: :ok,
              message: "",
              bootstrap_type: :full
            }
          },
          host_two => {
            groups: ["activemq::master"],
            result: {
              status: :ok,
              message: "",
              bootstrap_type: :partial
            }
          }
        }
      end

      let(:manifest) do
        MB::Bootstrap::Manifest.new(node_groups: [
          {
            groups: ["activemq::master"],
            hosts: [ host_one, host_two ]
          }
        ])
      end

      it "sets the job to success" do
        manager.should_receive(:concurrent_bootstrap).and_return(response)
        job.should_receive(:report_success)

        run
      end
    end

    context "when there is an error in one or more nodes bootstrapped" do
      let(:host_one) { "euca-10-20-37-171.eucalyptus.cloud.riotgames.com" }
      let(:host_two) { "euca-10-20-37-172.eucalyptus.cloud.riotgames.com" }

      let(:response) do
        {
          host_one => {
            groups: ["activemq::master"],
            result: {
              status: :error,
              message: "something helpful",
              bootstrap_type: :full
            }
          },
          host_two => {
            groups: ["activemq::master"],
            result: {
              status: :ok,
              message: "",
              bootstrap_type: :partial
            }
          }
        }
      end

      let(:manifest) do
        MB::Bootstrap::Manifest.new(node_groups: [
          {
            groups: ["activemq::master"],
            hosts: [ host_one, host_two ]
          }
        ])
      end

      it "sets the job to success" do
        manager.should_receive(:concurrent_bootstrap).and_return(response)
        job.should_receive(:report_failure)

        run
      end
    end
  end

  describe "#concurrent_bootstrap" do
    let(:job) { MB::Job.new(:bootstrap) }
    let(:tasks) { Array.new }
    let(:instructions) { MB::Bootstrap::Routine.map_instructions(tasks, manifest) }
    let(:worker_pool) { double('worker-pool') }
    let(:result) { manager.concurrent_bootstrap(job, manifest, instructions) }

    before { subject.stub(worker_pool: worker_pool) }

    context "with a manifest containing a node group with two groups and a task for each" do
      let(:tasks) do
        [
          MB::Bootstrap::Routine::Task.new("app_server::default",
            run_list: [ "recipe[one]", "recipe[two]" ],
            chef_attributes: { deep: { one: "val" } }
          ),
          MB::Bootstrap::Routine::Task.new("database_master::default",
            run_list: [ "recipe[three]" ],
            chef_attributes: { deep: { two: "val" } }
          )
        ]
      end

      let(:host_one) { "euca-10-20-37-171.eucalyptus.cloud.riotgames.com" }
      let(:host_two) { "euca-10-20-37-172.eucalyptus.cloud.riotgames.com" }

      let(:response_one) do
        double('future-one', value: {
          node:  host_one,
          status: :ok,
          message: "",
          bootstrap_type: :full
        })
      end

      let(:response_two) do
        double('future-two', value: {
          node: host_two,
          status: :error,
          message: "client verification error",
          bootstrap_type: :partial
        })
      end

      let(:manifest) do
        MB::Bootstrap::Manifest.new(
          nodes: [
            {
              groups: ["app_server::default", "database_master::default"],
              hosts: [ host_one, host_two ]
            }
          ]
        )
      end

      it "bootstraps a node only one time" do
        worker_pool.should_receive(:future).with(:run, host_one, anything).once.and_return(response_one)
        worker_pool.should_receive(:future).with(:run, host_two, anything).once.and_return(response_two)
        result
      end

      it "bootstraps each node with a merged run list from each task" do
        options = { chef_attributes: anything, run_list: ["recipe[one]", "recipe[two]", "recipe[three]"]}
        worker_pool.should_receive(:future).with(:run, host_one, options).once.and_return(response_one)
        worker_pool.should_receive(:future).with(:run, host_two, options).once.and_return(response_two)
        result
      end

      it "bootstraps each node with merged chef attributes from each task" do
        chef_attributes = Hashie::Mash.new(deep: { one: "val", two: "val" })
        options = { chef_attributes: chef_attributes, run_list: anything }
        worker_pool.should_receive(:future).with(:run, host_one, options).once.and_return(response_one)
        worker_pool.should_receive(:future).with(:run, host_two, options).once.and_return(response_two)
        result
      end
    end

    context "when there are no nodes in the manifest" do
      let(:manifest) { MB::Bootstrap::Manifest.new }

      it "returns an empty Hash" do
        expect(result).to be_empty
      end
    end

    context "given an empty array of tasks" do
      let(:tasks) { Array.new }

      it "returns an empty Hash" do
        expect(result).to be_empty
      end
    end
  end
end
