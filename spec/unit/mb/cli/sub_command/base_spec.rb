require 'spec_helper'

describe MB::Cli::SubCommand::Base do
  let(:thor_cli) do
    Class.new(MB::Cli::SubCommand::Base)
  end

  describe "::fabricate" do
    it "raises an AbstractFunction error when not implemented" do
      lambda {
        thor_cli.fabricate
      }.should raise_error(MB::AbstractFunction)
    end
  end

  describe "::define_task" do
    let(:scope) { MB::Plugin.new(double('component', name: 'chat', version: "1.2.3", valid?: true)) }
    let(:command) do
      MB::Command.new(:my_command, scope) do
        execute do
          # nothing
        end
      end
    end

    subject do
      thor_cli.define_task(command)
      thor_cli
    end

    let(:defined_task) { subject.tasks[command.name] }

    it "adds a Thor task matching the name of the given command" do
      defined_task.name.should eql(command.name)
    end

    it "has a description matching the description of given command" do
      defined_task.description.should eql(command.description)
    end

    it "takes a variable amount of arguments" do
      subject.instance_method(command.name.to_sym).parameters.should eql([[:rest, :arguments]])
    end

    context "when the execute block takes no arguments" do
      let(:command) do
        MB::Command.new(:my_command, scope) do
          execute do
            # nothing
          end
        end
      end

      it "has a usage only containing the name of the task" do
        defined_task.usage.should eql(command.name)
      end
    end

    context "when the execute block takes additional arguments" do
      let(:command) do
        MB::Command.new(:my_command, scope) do
          execute do |first, second, third|
            # nothing
          end
        end
      end

      it "has a usage only containing the name of the task" do
        defined_task.usage.should eql("#{command.name} FIRST SECOND THIRD")
      end
    end
  end
end
