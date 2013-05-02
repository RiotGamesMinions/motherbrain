require 'spec_helper'

describe MB::CommandRunner do
  let(:scope) { MB::Plugin.new(double(valid?: true)) }

  let(:action_1) { double('action_1', name: "action 1") }
  let(:action_2) { double('action_2', name: "action 2") }

  let(:actions) { [ action_1, action_2 ] }

  let(:node_1) { double('node_1', name: 'a.riotgames.com', public_hostname: 'a.riotgames.com') }
  let(:node_2) { double('node_2', name: 'b.riotgames.com', public_hostname: 'b.riotgames.com') }
  let(:node_3) { double('node_3', name: 'c.riotgames.com', public_hostname: 'c.riotgames.com') }
  let(:nodes) { [ node_1, node_2, node_3 ] }

  let(:master_group) { double('master_group', nodes: [ node_1, node_2 ]) }
  let(:slave_group) { double('slave_group', nodes: [ node_3 ]) }

  let(:environment) { "rspec-test" }
  let(:job) { double('job', set_status: nil) }

  subject { MB::CommandRunner }

  before(:each) do
    MB::CommandRunner::CleanRoom.stub_chain(:new, :actions).and_return(actions)
  end

  describe "#on" do
    it "should raise an exception if it has no block" do
      command_block = Proc.new do
        on("master_group")
      end

      lambda { subject.new(job, environment, scope, command_block)}.should raise_error(MB::PluginSyntaxError)
    end

    it "has a single group" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, master_group.nodes, true)
      end

      command_block = Proc.new do
        on("master_group") do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    it "has multiple groups" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, nodes, true)
      end

      command_block = Proc.new do
        on("master_group", "slave_group") do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    it "has multiple groups and an option" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, [anything()], true).exactly(3).times
      end

      command_block = Proc.new do
        on("master_group", "slave_group", max_concurrent: 1) do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    it "can run on any 1 node" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, [anything()], true)
      end

      command_block = Proc.new do
        on("master_group", any: 1) do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    it "can only run on one node at a time" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, [node_1], true)
        action.should_receive(:run).with(job, environment, [node_2], true)
      end

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    it "has multiple on blocks" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(job, environment, [node_1], true).exactly(2).times
        action.should_receive(:run).with(job, environment, [node_2], true).exactly(2).times
        action.should_receive(:run).with(job, environment, [node_3], true).exactly(1).times
      end

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end

        on("slave_group") do
          # block
        end
      end

      subject.new(job, environment, scope, command_block)
    end
  end

  describe "#async" do
    it "is ran asynchronously" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      subject.any_instance.should_receive(:run).exactly(1).times

      node_querier.should_receive(:bulk_chef_run)

      command_block = Proc.new do
        async do
          on("master_group", max_concurrent: 1) do
            # block
          end

          on("slave_group") do
            # block
          end
        end
      end

      subject.new(job, environment, scope, command_block)
    end

    context "when there are no nodes in the target groups" do
      let(:empty_group) { double('empty_group', nodes: Array.new) }

      it "runs no actions" do
        scope.should_receive(:group!).with("empty_group").and_return(empty_group)

        command_block = Proc.new do
          on("empty_group") do
            # block
          end
        end

        actions.each { |action| action.should_not_receive(:run) }

        subject.new(job, environment, scope, command_block)
      end
    end

    context "with a wait command" do
      let(:empty_group) { double('empty_group', nodes: Array.new) }

      it "sleeps" do
        pending "Unsure which mock is receiving #wait"

        Celluloid.should_receive(:sleep).with(1)

        command_block = Proc.new do
          on("empty_group") do
            wait 1
          end
        end

        subject.new(job, environment, scope, command_block)
      end
    end
  end

  describe "#component" do
    let(:component) { double('component', name: "foo") }
    let(:proxy) { subject.new(job, environment, scope, Proc.new {}).component("foo") }

    before do
      scope.should_receive(:component).with("foo").and_return(component)
    end

    it "returns a proxy" do
      proxy.should be_an_instance_of(MB::CommandRunner::InvokableComponent)
    end

    it "sets the component on the proxy" do
      proxy.component.should eq(component)
    end

    it "invokes the real component" do
      component.should_receive(:invoke).with(environment, "bar", [])
      proxy.invoke("bar")
    end
  end

  describe "#command" do
    let(:command) do
      MB::Command.new("foo", scope) do
        description "test command"
        execute do
          # nothing
        end
      end
    end

    before do
      scope.should_receive(:command!).with("foo").and_return(command)
    end

    it "is invoked" do
      subject.new(job, environment, scope, Proc.new {}).command("foo")
    end
  end
end
