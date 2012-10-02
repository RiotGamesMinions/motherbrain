require 'spec_helper'

describe "loading a plugin" do
  let(:dsl_content) do
    <<-EOH
      name "pvpnet"
      version "1.2.3"
      description "whatever"
      author "Jamie Winsor"
      email "jamie@vialstudios.com"

      depends "pvpnet", "~> 1.2.3"
      depends "activemq", "= 4.2.1"

      command do
        name "start"
        description "Start all services"

        execute do
          component(:activemq).invoke(:start)
        end
      end

      component do
        name "activemq"
        description "do stuff to AMQ"
        
        group do
          name "master_broker"

          recipe "activemq::broker"
          role "why_man_why"
          chef_attribute 'activemq.broker.master', true
        end

        service do
          name "broker"
          
          action :start do
            set_attribute('activemq.broker.status', true)
          end

          action :stop do
            set_attribute('activemq.broker.status', false)
          end
        end

        command do
          name "start"
          description "Start activemq services"

          execute do
            run do
              service(:broker, :start).on(:master_broker)
            end
          end
        end

        command do
          name "stop"
          description "Stop activemq services"

          execute do
            run.service(:broker, :stop).on(:master_broker)
          end
        end
      end
    EOH
  end

  before(:each) { @plugin = MB::Plugin.load(dsl_content) }
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

  describe "component" do
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
      it { subject.commands[0].name.should eql("start") }
      it { subject.commands[1].name.should eql("stop") }
    end
  end

  describe "commands" do
    subject { @plugin.commands }

    it { subject[0].should be_a(MB::Command) }
  end
end
