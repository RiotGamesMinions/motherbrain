require 'spec_helper'

describe MB::Cli::SubCommand::Plugin do
  describe "ClassMethods" do
    subject { described_class }

    let(:metadata) do
      double('metadata',
        valid?: true,
        name: "pvpnet",
        version: "1.2.3"
      )
    end

    let(:plugin) do
      MB::Plugin.new(metadata) do
        component "activemq" do
          description "activemq stuff"

          command "start" do
            description "start stuff"
            execute do; end
          end
        end
      end
    end

    describe "::fabricate" do
      it "returns an anonymous class with a superclass of MB::Cli::SubCommand::Plugin" do
        klass = subject.fabricate(plugin)
        
        klass.superclass.should eql(MB::Cli::SubCommand::Plugin)
        klass.should be_a(Class)
      end

      it "sets the plugin class attribute of the fabricated class to the given plugin" do
        subject.fabricate(plugin).plugin.should eql(plugin)
      end

      it "sets the namespace of the fabricated class to the name of the given plugin" do
        subject.fabricate(plugin).namespace.should eql(plugin.name)
      end

      describe "fabricated class" do
        it "has a task for each of the fabricated class' plugin's commands" do
          tasks = subject.fabricate(plugin).tasks

          plugin.commands.each do |command|
            tasks.should have_key(command.name)
          end
        end

        it "has a new for every component of the fabricated class' plugin" do
          subcommands = subject.fabricate(plugin).subcommands

          subcommands.should have(plugin.components.length).items
          plugin.components.each do |component|
            subcommands.should include(component.name)
          end
        end

        context "when the plugin has a bootstrap_routine" do
          before(:each) do
            plugin.stub(:bootstrap_routine).and_return(double('routine'))
          end

          it "has a bootstrap task" do
            subject.fabricate(plugin).tasks.should have_key("bootstrap")
          end

          it "has a 'provision' task" do
            subject.fabricate(plugin).tasks.should have_key("provision")
          end
        end

        context "when a plugin does not have a bootstrap_routine" do
          before(:each) do
            plugin.stub(:bootstrap_routine).and_return(nil)
          end

          it "does not have a 'bootstrap' task" do
            subject.fabricate(plugin).tasks.should_not have_key("bootstrap")
          end

          it "does not have a 'provision' task" do
            subject.fabricate(plugin).tasks.should_not have_key("provision")
          end
        end
      end
    end
  end
end
