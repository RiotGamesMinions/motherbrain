require 'spec_helper'

describe "loading a plugin" do
  let(:dsl_content) do
    <<-EOH
      name "reset"
      version "1.2.3"
      description "whatever"
      author "Jamie Winsor"
      email "jamie@vialstudios.com"

      command :start do
        component(:activemq).invoke(:start)
      end

      component :pvpnet do
        group :database do
          recipe "pvpnet::database"
          role "why_man_why"
          attribute 'pvpnet.database.master', true
        end
      end
    EOH
  end

  before(:each) { @plugin = MB::Plugin.load(dsl_content) }
  subject { @plugin }

  it { subject.name.should eql("reset") }
  it { subject.version.should eql("1.2.3") }
  it { subject.description.should eql("whatever") }
  it { subject.author.should eql("Jamie Winsor") }
  it { subject.email.should eql("jamie@vialstudios.com") }

  it { subject.components.should have(1).item }
  it { subject.component(:pvpnet).should_not be_nil }

  it { subject.commands.should have(1).item }
  it { subject.command(:start).should_not be_nil }

  describe "component" do
    subject { @plugin.component(:pvpnet) }

    it { subject.groups.should have(1).item }
    it { subject.group(:database).should_not be_nil }

    describe "group" do
      subject { @plugin.component(:pvpnet).group(:database) }

      it { subject.recipes.should have(1).item }
      it { subject.recipes.should include("pvpnet::database") }

      it { subject.roles.should have(1).item }
      it { subject.roles.should include("why_man_why") }

      it { subject.attributes.should have(1).item }
      it { subject.attributes.should include("pvpnet.database.master" => true) }
    end
  end

  describe "commands" do
    subject { @plugin.commands }

    it { subject[0].should be_a(Proc) }
  end
end
