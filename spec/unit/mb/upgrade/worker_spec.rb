require 'spec_helper'

describe MB::Upgrade::Worker do
  subject { worker }

  let(:worker) { klass.new(environment_name, plugin, job, options).wrapped_object }

  let(:component1) { MB::Component.new component_name }
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
      environment: environment,
      nodes: nodes,
      set_component_versions: nil,
      set_cookbook_versions: nil,
      save_environment: true,
      run_chef: true
    )
    plugin.stub(:component!).with(component_name).and_return(component1)
  end

  its(:environment_name) { should == environment_name }
  its(:plugin) { should == plugin }
  its(:options) { should == options }

  describe "#run" do
    after(:each) { job.terminate }

    subject(:run) { worker.run }

    it "wraps the upgrade in a lock" do
      MB::ChefMutex.any_instance.should_receive :synchronize

      run
    end

    it "returns a Job" do
      run.should be_a(MB::Job)
    end

    it "marks the job as 'running' and then 'success' if successful" do
      job.should_receive(:report_running)
      job.should_receive(:report_success)

      run
    end

    context "when an environment does not exist" do
      before { worker.stub(environment: nil) }

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
  end

  describe "#assert_environment_exists" do
    subject(:assert_environment_exists) {
      worker.send :assert_environment_exists
    }

    it { should be_nil }

    context "when the environment does not exist" do
      before do
        worker.stub environment: nil
      end

      it "raises an error" do
        -> {
          assert_environment_exists
        }.should raise_error MB::EnvironmentNotFound
      end
    end
  end

  describe "#override_attributes" do
    subject(:override_attributes) { worker.send :override_attributes }

    let(:version_attribute) { "my.custom.version" }

    before do
      worker.stub component_versions: component_versions

      worker.stub(
        :version_attribute
      ).with(
        component_name
      ).and_return(
        version_attribute
      )
    end

    it "returns a hash of version attributes and versions" do
      should == { "my.custom.version" => component_versions[component_name]  }
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

  describe "#save_environment" do
    subject(:save_environment) { worker.send :save_environment }

    before do
      worker.unstub :save_environment
    end

    it "saves the environment" do
      environment.should_receive :save

      save_environment
    end
  end

  describe "#set_component_versions" do
    subject(:set_component_versions) { worker.send :set_component_versions }

    before do
      worker.unstub :set_component_versions
    end

    it "sets the override attributes" do
      worker.should_receive :set_override_attributes

      set_component_versions
    end
  end

  describe "#set_override_attributes" do
    subject(:set_override_attributes) { worker.send :set_override_attributes }

    before do
      environment.stub override_attributes: {}
    end

    it "merges our override attributes" do
      environment.override_attributes.should_receive(:merge!).with({})

      set_override_attributes
    end
  end

  describe "#set_cookbook_versions" do
    subject(:set_cookbook_versions) { worker.send :set_cookbook_versions }

    before do
      worker.unstub :set_cookbook_versions

      environment.stub cookbook_versions: {}
    end

    it "merges our cookbook versions" do
      environment.cookbook_versions.should_receive(:merge!).with({})

      set_cookbook_versions
    end
  end

  describe "#version_attribute" do
    subject(:version_attribute) { worker.send :version_attribute, component_name }

    before do
      plugin.stub components: components
    end

    it "raises an error" do
      -> { version_attribute }.should raise_error MB::ComponentNotVersioned
    end

    context "with a component version" do
      before do
        component1.stub version_attribute: "my.custom.version"
      end

      it { should == "my.custom.version" }
    end
  end
end
