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
    let(:node_querier) { double('node_querier', bulk_chef_run: nil) }

    before(:each) do
      MB::Gear::Service::ActionRunner.stub(:new).and_return(runner)
      MB::Gear::Service::Action.any_instance.stub(:node_querier).and_return(node_querier)
    end

    it "runs Chef on every node" do
      expect(node_querier).to receive(:bulk_chef_run).with(job, nodes, nil)
      subject.run(job, environment, nodes)
    end

    it "resets the ActionRunner" do
      runner.should_receive(:reset)

      subject.run(job, environment, [])
    end
  end
end
