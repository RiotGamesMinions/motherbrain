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

    let(:runner) { double('action_runner', reset: nil, run: nil, service_recipe: nil) }
    let(:key) { "some.attr" }
    let(:value) { "val" }
    let(:chef_success) { double('success-response', error?: false, host: nil) }
    let(:chef_run_options) { { override_recipe: nil } }

    before(:each) do
      MB::Gear::Service::ActionRunner.stub(:new).and_return(runner)
    end

    it "runs Chef on every node" do
      MB::Application.node_querier.should_receive(:chef_run).with(node_1.public_hostname, chef_run_options).
        and_return(chef_success)
      MB::Application.node_querier.should_receive(:chef_run).with(node_2.public_hostname, chef_run_options).
        and_return(chef_success)
      MB::Application.node_querier.should_receive(:chef_run).with(node_3.public_hostname, chef_run_options).
        and_return(chef_success)

      subject.run(job, environment, nodes)
    end

    it "resets the ActionRunner" do
      runner.should_receive(:reset)

      subject.run(job, environment, [])
    end
  end
end
