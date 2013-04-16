require 'spec_helper'

describe MB::Upgrade::Worker do
  subject { worker }

  let(:worker) { klass.new(job, environment_name, plugin, options).wrapped_object }

  let(:component1) { MB::Component.new(component_name, plugin) }
  let(:component_name) { "component1" }
  let(:component_versions) { { component_name => "1.2.3" } }
  let(:components) { [component1] }
  let(:cookbook_versions) { { "ohai" => "1.2.3" } }
  let(:environment) { stub }
  let(:environment_name) { "rspec-test" }
  let(:job) { MB::Job.new(:upgrade) }
  let(:options) { Hash.new }
  let(:nodes) { %w[node1 node2 node3] }
  let(:plugin) { stub MB::Plugin, name: plugin_name }
  let(:plugin_name) { "plugin_name" }

  before do
    worker.stub(
      assert_environment_exists: true,
      nodes: nodes,
      set_component_versions: nil,
      set_cookbook_versions: nil,
      save_environment: true,
      run_chef: true
    )
    plugin.stub(:component!).with(component_name).and_return(component1)
  end

  after(:each) { job.terminate if job.alive? }

  its(:environment_name) { should == environment_name }
  its(:plugin) { should == plugin }
  its(:options) { should == options }

  describe "#run" do
    subject(:run) { worker.run }

    it "wraps the upgrade in a lock" do
      MB::ChefMutex.any_instance.should_receive :synchronize

      run
    end

    it "returns a Job" do
      run.should be_a(MB::Job)
    end

    it "marks the job as 'running' and then 'success' if successful" do
      job.should_receive(:report_running).ordered
      job.should_receive(:report_success).ordered

      run
    end

    context "when an environment does not exist" do
      before do
        worker.stub(:assert_environment_exists).and_raise(MB::EnvironmentNotFound.new(environment_name))
      end

      it "should set the job state to :failure" do
        run
        job.should be_failure
      end
    end

    context "when no component_versions or cookbook_versions are passed" do
      before do
        options[:cookbook_versions] = nil
        options[:component_versions] = nil
      end

      it "does not save the environment, nor run chef" do
        worker.should_not_receive :run_chef

        run
      end
    end

    context "when only cookbook_versions is passed as an option" do
      before do
        options[:cookbook_versions] = cookbook_versions
        options[:component_versions] = nil
      end

      it "updates only the cookbook versions and runs chef" do
        worker.should_receive(:set_cookbook_versions).ordered
        worker.should_receive(:run_chef).ordered

        worker.should_not_receive :set_component_versions

        run
      end
    end

    context "when only component_versions is passed as an option" do
      before do
        options[:cookbook_versions] = nil
        options[:component_versions] = component_versions
      end

      it "updates only the component versions and runs chef" do
        worker.should_receive(:set_component_versions).ordered
        worker.should_receive(:run_chef).ordered

        worker.should_not_receive :set_cookbook_versions

        run
      end
    end

    context "when both component_versions and cookbook_versions are passed as options" do
      before do
        options[:cookbook_versions] = cookbook_versions
        options[:component_versions] = component_versions
      end

      it "updates the versions and runs chef" do
        worker.should_receive(:set_component_versions).ordered
        worker.should_receive(:set_cookbook_versions).ordered
        worker.should_receive(:run_chef).ordered

        run
      end
    end

    context "when no nodes exist in the environment" do
      before do
        options[:cookbook_versions] = cookbook_versions
        options[:component_versions] = component_versions

        worker.stub nodes: []
      end

      it "updates the versions and does not run chef" do
        worker.should_receive(:set_component_versions).ordered
        worker.should_receive(:set_cookbook_versions).ordered

        worker.should_not_receive :run_chef

        run
      end
    end

    context "when environment_attributes_file is passed as an option" do
      let(:filepath) { double }

      before do
        options[:environment_attributes_file] = filepath
      end

      it "sets environment attributes on the environment with the contents of the file" do
        worker.should_receive(:set_environment_attributes_from_file).with(environment_name, filepath).ordered

        run
      end

      context "when the environment attributes file is invalid" do
        it "sets the job to failed" do
          worker.should_receive(:set_environment_attributes_from_file).and_raise(MB::InvalidAttributesFile)
          run

          job.should be_failure
        end
      end
    end

    context "when environment_attributes_file is not passed as an option" do
      before do
        options[:environment_attributes_file] = nil
      end

      it "does not set the environment attributes on the environment" do
        worker.should_not_receive(:set_environment_attributes_file)

        run
      end
    end

    context "when environment_attributes is passed as an option" do
      let(:env_attributes) do
        {
          "foo" => "bar",
          "baz.quux" => 42
        }
      end

      before do
        options[:environment_attributes] = env_attributes
      end

      it "sets environment attributes on the environment" do
        worker.should_receive(:set_environment_attributes).with(environment_name, env_attributes).ordered

        run
      end
    end

    context "when environment_attributes is not passed as an option" do
      before do
        options[:environment_attributes] = nil
      end

      it "does not set the environment attributes on the environment" do
        worker.should_not_receive(:set_environment_attributes)

        run
      end
    end
  end

  describe "#nodes" do
    pending "This should not be the responsibility of MB::Upgrade"
  end

  describe "#run_chef" do
    subject(:run_chef) { worker.send :run_chef }

    let(:nodes) { %w[node1 node2 node3] }

    before do
      worker.unstub :run_chef

      worker.stub nodes: nodes
    end

    it "runs chef on the nodes" do
      nodes.each do |node|
        MB::Application.node_querier.should_receive(:chef_run).with(node)
      end

      run_chef
    end
  end
end
