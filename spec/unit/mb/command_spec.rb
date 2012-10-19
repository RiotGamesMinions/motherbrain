require 'spec_helper'

describe MB::Command do
  let(:scope) { double('plugin') }

  describe "ClassMethods" do
    subject { MB::Command }

    describe "::new" do
      before(:each) do
        @command = subject.new("start", @context, scope) do
          description "start all services"

          execute do
            4 + 2
          end
        end
      end

      it "assigns a name from the given block" do
        @command.name.should eql("start")
      end

      it "assigns a description from the given block" do
        @command.description.should eql("start all services")
      end

      it "assigns a Proc as the value for execute" do
        @command.execute.should be_a(Proc)
      end
    end
  end
end

describe MB::Command::CommandRunner do
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

  subject { MB::Command::CommandRunner }

  describe "#async" do
  end

  describe "#on" do

    before(:each) do
      MB::Command::CommandRunner::CleanRoom.stub_chain(:new, :actions).and_return(actions)
    end

    it "should raise an exception if it has no block" do
      command_block = Proc.new do
        on("master_group")
      end
      
      lambda { subject.new(@context, scope, command_block)}.should raise_error(MB::PluginSyntaxError)
    end

    it "has a single group" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      command_block = Proc.new do
        on("master_group") do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      actual_actions, node_groups = command_runner.run_groups.first
      actual_actions.should =~ actions
      node_groups.first.should =~ master_group.nodes
    end

    it "has multiple groups" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      command_block = Proc.new do
        on("master_group", "slave_group") do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      actual_actions, node_groups = command_runner.run_groups.first
      actual_actions.should =~ actions
      node_groups.first.should =~ nodes
    end

    it "has multiple groups and an option" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      command_block = Proc.new do
        on("master_group", "slave_group", max_concurrent: 1) do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      actual_actions, node_groups = command_runner.run_groups.first
      actual_actions.should =~ actions
      node_groups.should =~ [[node_1], [node_2], [node_3]]
    end

    it "can run on any 1 node" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      command_block = Proc.new do
        on("master_group", any: 1) do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      actual_actions, node_groups = command_runner.run_groups.first
      actual_actions.should =~ actions
      node_groups.should =~ [[node_1]]
    end

    it "can only run on one node at a time" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      actual_actions, node_groups = command_runner.run_groups.first
      actual_actions.should =~ actions
      node_groups.should =~ [[node_1], [node_2]]
    end

    it "has multiple on blocks" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      command_block = Proc.new do
        on("master_group", max_concurrent: 1) do
          # block
        end

        on("slave_group") do
          # block
        end
      end
      
      command_runner = subject.new(@context, scope, command_block)
      master_actions, master_node_groups = command_runner.run_groups.first
      master_actions.should =~ actions
      master_node_groups.should =~ [[node_1], [node_2]]

      slave_actions, slave_node_groups = command_runner.run_groups.second
      slave_actions.should =~ actions
      slave_node_groups.should =~ [[node_3]]
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

        subject.new(@context, scope, command_block)
      end
    end
  end
end
