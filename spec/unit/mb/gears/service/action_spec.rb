require 'spec_helper'

describe MB::Gear::Service::Action do
  let(:component) { double('component', name: 'test-component') }
  let(:job) { double('job', set_status: nil) }
  let(:klass) { described_class }

  let(:environment) { "rspec-test" }
  let(:node_1) { double('node_1', name: 'reset', public_hostname: 'reset.riotgames.com') }
  let(:node_2) { double('node_2', name: 'jwinsor', public_hostname: 'jwinsor.riotgames.com') }
  let(:node_3) { double('node_3', name: 'jwinsor-2', public_hostname: 'jwinsor-2.riotgames.com') }
  let(:nodes) { [ node_1, node_2, node_3 ] }

  describe "#run" do
    subject do
      klass.new(:start, component) do
        # block
      end
    end

    let(:runner) { double('action_runner', reset: nil, run: nil) }
    let(:key) { "some.attr" }
    let(:value) { "val" }
    let(:chef_success) { double('success-response', error?: false, host: nil) }

    before(:each) do
      MB::Gear::Service::ActionRunner.stub(:new).and_return(runner)
    end

    it "runs Chef on every node" do
      MB::Application.node_querier.should_receive(:chef_run).with(node_1.public_hostname).
        and_return(chef_success)
      MB::Application.node_querier.should_receive(:chef_run).with(node_2.public_hostname).
        and_return(chef_success)
      MB::Application.node_querier.should_receive(:chef_run).with(node_3.public_hostname).
        and_return(chef_success)

      subject.run(job, environment, nodes)
    end

    it "resets the ActionRunner" do
      runner.should_receive(:reset)

      subject.run(job, environment, [])
    end

    context "when an environment attribute is specified" do
      let(:key) { "some.attr" }
      let(:value) { "val" }

      subject do
        klass.new(:start, component) do
          environment_attribute("some.attr", "val")
        end
      end

      it "sets an environment attribute" do
        runner.should_receive(:environment_attribute).with(key, value)

        subject.run(job, environment, [])
      end

      context "when toggle: true" do
        subject do
          klass.new(:start, component) do
            environment_attribute("some.attr", "val", toggle: true)
          end
        end

        it "sets an environment attribute and then sets it back" do
          runner.should_receive(:environment_attribute).with(key, value, toggle: true)

          subject.run(job, environment, [])
        end
      end
    end

    context "when a node attribute is specified" do
      subject do
        klass.new(:start, component) do
          node_attribute("some.attr", "val", toggle: true)
        end
      end

      it "sets a node attribute on each node" do
        success = double('success-response', error?: false)
        MB::Gear::Service::ActionRunner.should_receive(:new).and_return(runner)
        MB::Application.node_querier.should_receive(:chef_run).exactly(3).times.and_return(chef_success)
        runner.should_receive(:node_attribute).with(key, value, toggle: true)

        subject.run(job, environment, nodes)
      end
    end
  end
end

