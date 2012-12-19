require 'spec_helper'

describe MB::CommandRunner do
  let(:scope) { double('plugin', name: "plugin") }

  let(:action_1) { double('action_1', name: "action 1") }
  let(:action_2) { double('action_2', name: "action 2") }

  let(:actions) { [ action_1, action_2 ] }

  let(:node_1) { double('node_1', name: 'reset.riotgames.com') }
  let(:node_2) { double('node_2', name: 'jwinsor.riotgames.com') }
  let(:node_3) { double('node_3', name: 'jwinsor.riotgames.com') }
  let(:nodes) { [ node_1, node_2, node_3 ] }

  let(:master_group) { double('master_group', nodes: [ node_1, node_2 ]) }
  let(:slave_group) { double('slave_group', nodes: [ node_3 ]) }

  let(:environment) { "rspec-test" }

  subject { MB::CommandRunner }

  before(:each) do
    MB::CommandRunner::CleanRoom.stub_chain(:new, :actions).and_return(actions)
  end

  describe "#on" do
    it "should raise an exception if it has no block" do
      command_block = Proc.new do
        on("master_group")
      end

      lambda { subject.new(environment, scope, command_block)}.should raise_error(MB::PluginSyntaxError)
    end

    it "has a single group" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, master_group.nodes)
      end

      command_block = Proc.new do
        on("master_group") do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end

    it "has multiple groups" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, nodes)
      end

      command_block = Proc.new do
        on("master_group", "slave_group") do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end

    it "has multiple groups and an option" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, [anything()]).exactly(3).times
      end

      command_block = Proc.new do
        on("master_group", "slave_group", max_concurrent: 1) do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end

    it "can run on any 1 node" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, [anything()])
      end

      command_block = Proc.new do
        on("master_group", any: 1) do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end

    it "can only run on one node at a time" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, [node_1])
        action.should_receive(:run).with(environment, [node_2])
      end

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end

    it "has multiple on blocks" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each do |action|
        action.should_receive(:run).with(environment, [node_1])
        action.should_receive(:run).with(environment, [node_2])
        action.should_receive(:run).with(environment, [node_3])
      end

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end

        on("slave_group") do
          # block
        end
      end

      subject.new(environment, scope, command_block)
    end
  end

  describe "#async" do
    it "is ran asynchronously" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      subject.any_instance.should_receive(:run).exactly(1).times

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

      subject.new(environment, scope, command_block)
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

        subject.new(environment, scope, command_block)
      end
    end
  end
end
