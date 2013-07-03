require 'spec_helper'

describe MB::CommandInvoker do
  let(:plugin_id) { "rspec-test" }
  let(:command_id) { "start" }
  let(:component_id) { "default" }
  let(:environment) { "rspec-testenv" }

  let(:options) do
    {
      version: "1.0.0"
    }
  end

  subject { described_class.new }

  describe "#async_invoke" do
    let(:job_ticket) { double(MB::JobRecord) }
    let(:job) { double(MB::Job, ticket: job_ticket) }
    let(:command_name) { "stop" }
    let(:options) { Hash.new }

    before do
      MB::Job.stub(:new).and_return(job)
    end

    it "asynchronously calls {#invoke}" do
      subject.should_receive(:async).with(:invoke, job, command_name, options)

      subject.async_invoke(command_name, options)
    end

    it "returns a JobRecord" do
      subject.stub(:async).with(:invoke, job, command_name, options)

      subject.async_invoke(command_name, options).should eql(job_ticket)
    end
  end

  describe "#find" do
    let(:command) { "stop" }
    let(:plugin) { "test-plugin" }
    let(:options) do
      {
        version: nil,
        component: nil,
        environment: nil
      }
    end

    let(:run) { subject.find(command, plugin, options) }

    it "delegates to #find_latest" do
      subject.should_receive(:find_latest).with(command, plugin, options[:component])
      run
    end

    context "when given a value for :version" do
      before do
        options[:version] = "1.2.3"
      end

      it "delegates to #for_version" do
        subject.should_receive(:for_version).with(options[:version], command, plugin, options[:component])
        run
      end
    end

    context "when given a value for :environment" do
      before do
        options[:environment] = "test-env"
      end

      it "delegates to #for_environment" do
        subject.should_receive(:for_environment).with(options[:environment], command, plugin, options[:component])
        run
      end
    end
  end

  describe "#invoke" do
    let(:command_name) { "stop" }
    let(:command) { double(invoke: nil) }
    let(:plugin) { "chat" }
    let(:component) { "default" }
    let(:environment) { "rspec-test" }
    let(:version) { "1.2.3" }
    let(:job) { double(MB::Job, alive?: true, set_status: nil, terminate: nil) }
    let(:worker) { double('worker', alive?: true, terminate: nil) }
    let(:environment_manager) { double('env-man') }
    let(:options) do
      {
        plugin: plugin,
        component: component,
        environment: environment,
        version: version,
        arguments: Array.new
      }
    end

    let(:run) { subject.invoke(job, command_name, options) }

    before(:each) do
      MB::CommandInvoker::Worker.stub(:new).and_return(worker)
      subject.stub(find: command, environment_manager: environment_manager, plugin_manager: plugin_manager)
      job.stub(set_status: nil, report_running: nil, report_failure: nil, report_success: nil)
      environment_manager.stub(find: nil)
      worker.stub(run: nil)
    end

    it "wraps the invocation in a lock" do
      MB::ChefMutex.any_instance.should_receive :synchronize

      run
    end

    it "marks the job as running and then a success on success" do
      job.should_receive(:report_running).ordered
      job.should_receive(:report_success).ordered

      run
    end

    it "terminates the running job on completion" do
      job.should_receive(:terminate).once

      run
    end

    it "creates a new worker to run the command in" do
      MB::CommandInvoker::Worker.should_receive(:new).with(command, environment, nil).and_return(worker)

      run
    end

    it "runs the worker with the job and given arguments" do
      worker.should_receive(:run).with(job, options[:arguments])

      run
    end

    it "shuts the worker down after completion" do
      worker.should_receive(:terminate).once

      run
    end

    context "when the plugin option is nil" do
      before { options[:plugin] = nil }

      it "sets the job to failure" do
        job.should_receive(:report_failure)
        run
      end
    end

    context "when the environment option is nil" do
      before { options[:environment] = nil }

      it "sets the job to failure" do
        job.should_receive(:report_failure)
        run
      end
    end

    context "when the target environment does not exist" do
      let(:exception) { MB::EnvironmentNotFound.new(environment) }

      before do
        subject.should_receive(:find).
          with(command_name, plugin, component: component, environment: environment, version: version).
          and_raise(exception)
      end

      it "should set the job state to :failure" do
        job.should_receive(:report_failure).with(exception)

        run
      end
    end

    context "when a plugin of the given name is not found" do
      let(:exception) { MB::PluginNotFound.new(plugin) }

      before do
        subject.should_receive(:find).
          with(command_name, plugin, component: component, environment: environment, version: version).
          and_raise(exception)
      end

      it "sets the job to failure with a command not found message" do
        job.should_receive(:report_failure).with(exception)

        run
      end
    end

    context "when a component of the given name is not found" do
      let(:exception) { MB::ComponentNotFound.new(component, plugin) }

      before do
        subject.should_receive(:find).
          with(command_name, plugin, component: component, environment: environment, version: version).
          and_raise(exception)
      end

      it "sets the job to failure with a command not found message" do
        job.should_receive(:report_failure).with(exception)

        run
      end
    end

    context "when a plugin command for the given plugin is not found" do
      let(:exception) { MB::CommandNotFound.new(component, plugin) }

      before do
        subject.should_receive(:find).
          with(command_name, plugin, component: component, environment: environment, version: version).
          and_raise(exception)
      end

      it "completes the job as a failure with a command not found message" do
        job.should_receive(:report_failure).with(exception)

        run
      end
    end
  end
end
