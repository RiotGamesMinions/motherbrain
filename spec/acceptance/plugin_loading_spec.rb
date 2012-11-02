require 'spec_helper'

describe "loading a plugin", type: "acceptance" do
  let(:context) { MB::Context.new(@config) }

  let(:dsl_body) do
    proc {
      name "pvpnet"
      version "1.2.3"
      description "whatever"
      author "Jamie Winsor"
      email "jamie@vialstudios.com"

      depends "pvpnet", "~> 1.2.3"
      depends "activemq", "= 4.2.1"

      command "start" do
        description "Start all services"

        execute do
          component("activemq").invoke("start")
        end
      end

      component "activemq" do
        description "do stuff to AMQ"
        
        group "master_broker" do
          recipe "activemq::broker"
          role "why_man_why"
          chef_attribute 'activemq.broker.master', true
        end

        service "broker" do
          action :start do
            node_attribute('activemq.broker.status', true)
          end

          action :stop do
            node_attribute('activemq.broker.status', false)
          end
        end

        command "start" do
          description "Start activemq services"

          execute do
            on("master_broker") do
              service("broker").run(:start)
              service("broker").run(:start)
            end
          end
        end

        command "stop" do
          description "Stop activemq services"

          execute do
            on("master_broker") do
              service("broker").run(:stop)
            end
          end
        end
      end
    }
  end

  before(:each) do
    @plugin = MB::Plugin.load(context, &dsl_body)
  end

  subject { @plugin }

  it { subject.name.should eql("pvpnet") }
  it { subject.version.to_s.should eql("1.2.3") }
  it { subject.description.should eql("whatever") }
  it { subject.author.should eql("Jamie Winsor") }
  it { subject.email.should eql("jamie@vialstudios.com") }

  it { subject.components.should have(1).item }
  it { subject.component("activemq").should_not be_nil }

  it { subject.commands.should have(1).item }
  it { subject.command("start").should_not be_nil }

  it { subject.dependencies.should have(2).items }

  describe "dependencies" do
    subject { @plugin.dependencies }

    it { subject.should have_key("pvpnet") }
    it { subject["pvpnet"].should be_a(Solve::Constraint) }
    it { subject["pvpnet"].to_s.should eql("~> 1.2.3") }

    it { subject.should have_key("activemq") }
    it { subject["activemq"].should be_a(Solve::Constraint) }
    it { subject["activemq"].to_s.should eql("= 4.2.1") }
  end

  describe "commands" do
    it "invokes an async command" do
      pending

      subject.command("start").invoke.should be_a(MB::CommandRunner)
    end

    context "when a command is not found" do
      it "raises a CommandNotFound error" do
        lambda {
          subject.command("not_there")
        }.should raise_error(MB::CommandNotFound)
      end
    end
  end

  context "when a component is not found" do
    it "raises a ComponentNotFound error" do
      lambda {
        subject.component!("not_there")
      }.should raise_error(MB::ComponentNotFound)
    end
  end

  describe "components" do
    subject { @plugin.component("activemq") }

    it { subject.description.should eql("do stuff to AMQ") }

    it { subject.groups.should have(1).item }
    it { subject.group("master_broker").should_not be_nil }

    describe "group" do
      subject { @plugin.component("activemq").group("master_broker") }

      it { subject.recipes.should have(1).item }
      it { subject.recipes.should include("activemq::broker") }

      it { subject.roles.should have(1).item }
      it { subject.roles.should include("why_man_why") }

      it { subject.chef_attributes.should have(1).item }
      it { subject.chef_attributes.should include("activemq.broker.master" => true) }
    end

    it { subject.commands.should have(2).items }
    it { subject.commands.should each be_a(MB::Command) }

    describe "commands" do
      it { subject.command("start").should_not be_nil }
      it { subject.command("stop").should_not be_nil }

      it "invokes an async command" do
        pending
        subject.command("start").invoke.should be_a(MB::CommandRunner)
      end

      it "invokes a sync command" do
        pending
        subject.command("stop").invoke.should be_a(MB::CommandRunner)
      end
    end
  end
end
