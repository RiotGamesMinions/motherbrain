require 'spec_helper'

describe MB::CommandRunner do
  subject { command_runner }

  let(:command_runner) {
    described_class.new(job, environment, scope, command_block)
  }

  let(:scope) { MB::Plugin.new(double(valid?: true)) }

  let(:action_1) { double('action_1', name: "action 1", run: nil) }
  let(:action_2) { double('action_2', name: "action 2", run: nil) }

  let(:actions) { [action_1, action_2] }

  let(:node_1) { double('node_1', name: 'a.riotgames.com', public_hostname: 'a.riotgames.com') }
  let(:node_2) { double('node_2', name: 'b.riotgames.com', public_hostname: 'b.riotgames.com') }
  let(:node_3) { double('node_3', name: 'c.riotgames.com', public_hostname: 'c.riotgames.com') }
  let(:nodes) { [node_1, node_2, node_3] }

  let(:master_group) { double('master_group', nodes: [node_1, node_2]) }
  let(:slave_group) { double('slave_group', nodes: [node_3]) }

  let(:environment) { "rspec-test" }
  let(:job) { double('job', set_status: nil) }
  let(:args) { }
  let(:command_block) {
    proc {
      on("master_group") do
        # block
      end
    }
  }

  before(:each) do
    MB::CommandRunner::CleanRoom.stub_chain(:new, :actions).and_return(actions)

    scope.stub(:group!).with("master_group").and_return(master_group)
  end

  describe "#on" do
    context "with no block" do
      let(:command_block) {
        proc { on("master_group") }
      }

      it "should raise an exception" do
        -> { command_runner }.should raise_error(MB::PluginSyntaxError)
      end
    end

    it "has a single group" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)

      actions.each do |action|
        action.
          should_receive(:run).
          with(job, environment, master_group.nodes, true)
      end

      command_runner
    end

    context "with multiple groups" do
      let(:command_block) {
        proc {
          on("master_group", "slave_group") do
            # block
          end
        }
      }

      it "works" do
        scope.should_receive(:group!).with("master_group").and_return(master_group)
        scope.should_receive(:group!).with("slave_group").and_return(slave_group)

        actions.each do |action|
          action.should_receive(:run).with(job, environment, nodes, true)
        end

        command_runner
      end
    end

    context "with multiple groups and an option" do
      let(:command_block) {
        proc {
          on("master_group", "slave_group", max_concurrent: 1) do
            # block
          end
        }
      }

      it "works" do
        scope.should_receive(:group!).with("master_group").and_return(master_group)
        scope.should_receive(:group!).with("slave_group").and_return(slave_group)

        actions.each do |action|
          action.should_receive(:run).with(job, environment, [anything()], true).exactly(3).times
        end

        command_runner
      end
    end

    context "with any: 1" do
      let(:command_block) {
        proc {
          on("master_group", any: 1) do
            # block
          end
        }
      }

      it "works" do
        scope.should_receive(:group!).with("master_group").and_return(master_group)

        actions.each do |action|
          action.should_receive(:run).with(job, environment, [anything()], true)
        end

        command_runner
      end
    end

    context "with max_concurrent: 1" do
      let(:command_block) {
        proc {
          on("master_group", max_concurrent: 1) do
            # block
          end
        }
      }

      it "runs only on one node at a time" do
        scope.should_receive(:group!).with("master_group").and_return(master_group)

        actions.each do |action|
          action.should_receive(:run).with(job, environment, [node_1], true)
          action.should_receive(:run).with(job, environment, [node_2], true)
        end

        command_runner
      end
    end

    context "with multiple on blocks" do
      let(:command_block) {
        proc {
          on("master_group", max_concurrent: 1) do
            # block
          end

          on("slave_group") do
            # block
          end
        }
      }

      it "works" do
        scope.should_receive(:group!).with("master_group").and_return(master_group)
        scope.should_receive(:group!).with("slave_group").and_return(slave_group)

        actions.each do |action|
          action.should_receive(:run).with(job, environment, [node_1], true).once
          action.should_receive(:run).with(job, environment, [node_2], true).once
          action.should_receive(:run).with(job, environment, [node_3], true).once
        end

        command_runner
      end
    end
  end

  describe "#async" do
    let(:command_block) {
      proc {
        async do
          on("master_group", max_concurrent: 1) do
            # block
          end

          on("slave_group") do
            # block
          end
        end
      }
    }

    it "is ran asynchronously" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:group!).with("slave_group").and_return(slave_group)

      actions.each { |action| action.should_receive(:run).exactly(3).times }

      node_querier.should_receive(:bulk_chef_run)

      command_runner
    end

    context "when there are no nodes in the target groups" do
      let(:empty_group) { double('empty_group', nodes: Array.new) }
      let(:command_block) {
        proc {
          async do
            on("empty_group") do
              # block
            end
          end
        }
      }

      it "runs no actions" do
        scope.should_receive(:group!).with("empty_group").and_return(empty_group)

        actions.each { |action| action.should_not_receive(:run) }

        command_runner
      end
    end

    context "with a wait command" do
      let(:empty_group) { double('empty_group', nodes: Array.new) }
      let(:command_block) {
        proc {
          on("empty_group") do
            wait 1
          end
        }
      }

      it "sleeps" do
        pending "Unsure which mock is receiving #wait"

        Celluloid.should_receive(:sleep).with(1)

        command_runner
      end
    end
  end

  describe "#component" do
    let(:component) { double('component', name: "foo") }
    let(:proxy) { command_runner.component("foo") }

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

    it "is invoked" do
      scope.should_receive(:group!).with("master_group").and_return(master_group)
      scope.should_receive(:command!).with("foo").and_return(command)

      command_runner.command("foo")
    end
  end
end
