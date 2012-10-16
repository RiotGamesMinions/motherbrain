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
  let(:nodes) { [ node_1, node_2 ] }

  let(:group) { double('group', nodes: nodes) }

  subject { MB::Command::CommandRunner }

  describe "#on" do
    before(:each) do
      @proc = Proc.new do
        on("group") do
          # block
        end
      end

      MB::Command::CommandRunner::CleanRoom.stub_chain(:new, :actions).and_return(actions)

      actions.each do |action|
        action.should_receive(:run).with(nodes)
      end

      scope.stub(:group!).and_return(group)
    end

    it "initializes" do
      subject.new(@context, scope, @proc)
    end
  end
end
