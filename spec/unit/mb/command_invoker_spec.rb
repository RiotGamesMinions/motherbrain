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
  after { subject.terminate if subject && subject.alive? }

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

  describe "#find_command" do
    pending
  end

  describe "#invoke" do
    let(:command_name) { "stop" }
    let(:command) { double(invoke: nil) }
    let(:plugin) { "chat" }
    let(:component) { "default" }
    let(:environment) { "rspec-test" }
    let(:job) { double(MB::Job) }
    let(:environment_manager) { double('env-man') }
    let(:options) do
      {
        plugin: plugin,
        component: component,
        environment: environment,
        arguments: Array.new
      }
    end

    let(:run) { subject.invoke(job, command_name, options) }

    before(:each) do
      subject.stub(find_command: command, environment_manager: environment_manager)
      job.stub(set_status: nil, alive?: true, report_running: nil, report_failure: nil, report_success: nil)
      job.should_receive(:terminate).once
      environment_manager.stub(find: nil)
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

    it "delegates to the loaded command to invoke" do
      command.should_receive(:invoke).with(environment, *options[:arguments])

      run
    end

    context "when the plugin option is nil" do
      before do
        options[:plugin] = nil
        job.stub(:report_failure)
      end

      it "raises a RuntimeError" do
        expect {
          run
        }.to raise_error(RuntimeError)
      end
    end

    context "when the target environment does not exist" do
      let(:exception) { MB::EnvironmentNotFound.new(environment) }

      before do
        subject.should_receive(:find_command).and_raise(exception)
      end

      it "should set the job state to :failure" do
        job.should_receive(:report_failure).with(exception.to_s)

        run
      end
    end

    context "when a plugin of the given name is not found" do
      let(:exception) { MB::PluginNotFound.new(plugin) }

      before do
        subject.should_receive(:find_command).and_raise(exception)
      end

      it "sets the job to failure with a command not found message" do
        job.should_receive(:report_failure).with(exception.to_s)

        run
      end
    end

    context "when a component of the given name is not found" do
      let(:exception) { MB::ComponentNotFound.new(component, plugin) }

      before do
        subject.should_receive(:find_command).and_raise(exception)
      end

      it "sets the job to failure with a command not found message" do
        job.should_receive(:report_failure).with(exception.to_s)

        run
      end
    end

    context "when a plugin command for the given plugin is not found" do
      let(:exception) { MB::CommandNotFound.new(component, plugin) }

      before do
        subject.should_receive(:find_command).and_raise(exception)
      end

      it "completes the job as a failure with a command not found message" do
        job.should_receive(:report_failure).with(exception.to_s)

        run
      end
    end
  end
end
