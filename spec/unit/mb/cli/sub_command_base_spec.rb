require 'spec_helper'

describe MB::Cli::SubCommandBase do
  let(:thor_cli) do
    Class.new(MB::Cli::SubCommandBase)
  end

  describe "::fabricate" do
    it "raises an AbstractFunction error when not implemented" do
      lambda {
        thor_cli.fabricate
      }.should raise_error(MB::AbstractFunction)
    end
  end

  describe "::define_task" do
    subject(:define_task) { thor_cli.send :define_task, command }

    let(:command) {
      MB::Command.new(:my_command, scope) do
        execute do
          nil
        end
      end
    }

    let(:my_command) { thor_cli.instance_method :my_command }

    let(:scope) { stub(MB::Plugin) }

    before do
      define_task
    end

    it "defines the command" do
      my_command.parameters.should == [[:req, :environment]]
    end

    context "with arguments" do
      let(:command) {
        MB::Command.new(:my_command, scope) do
          execute do |a|
            nil
          end
        end
      }

      it "has an extra argument" do
        my_command.parameters.should == [
          [:req, :environment],
          [:req, :a]
        ]
      end
    end
  end
end
