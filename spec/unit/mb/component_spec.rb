require 'spec_helper'

describe MB::Component do
  let(:environment) { 'mb-test' }
  let(:chef_conn) { double('chef_conn') }
  let(:plugin) { double(MB::Plugin) }

  subject { component }

  let(:component) {
    MB::Component.new("activemq", plugin) do
      group "masters" do
        # block
      end
    end
  }

  describe "#command" do
    let(:component) do
      MB::Component.new("activemq", plugin) do
        command "existing" do
          # block
        end
      end
    end

    subject { component.command(name) }

    context "when the component has a command matching the given name" do
      let(:name) { "existing" }

      it { should be_a(MB::Command) }
      it { name.should eql("existing") }
    end

    context "when the component does not have a command matching the given name" do
      let(:name) { "not-there" }

      it { should be_nil }
    end
  end

  describe "#command!" do
    before do
      subject.stub(command: nil)
    end

    it "raises a CommandNotFound error when no matching command is present" do
      expect {
        subject.command!("stop")
      }.to raise_error(MB::CommandNotFound)
    end
  end

  describe "#description" do
    subject { component.description }

    it { should eq("activemq component commands") }

    context "with a description" do
      let(:component) {
        MB::Component.new("activemq", plugin) do
          description "ActiveMQ"
        end
      }

      it { should eq("ActiveMQ") }
    end
  end

  describe "#groups" do
    subject do
      MB::Component.new("activemq", plugin) do
        group "masters" do
          # block
        end
      end
    end

    it "returns a Set of Group objects" do
      subject.groups.should be_a(Set)
      subject.groups.should each be_a(MB::Group)
    end
  end

  describe "#group" do
    subject do
      MB::Component.new("activemq", plugin) do
        group "masters" do
          # block
        end
      end
    end

    it "returns the group matching the given name" do
      subject.group("masters").name.should eql("masters")
    end
  end

  describe "#group!" do
    subject do
      MB::Component.new("activemq", plugin) do
        group "masters" do
          # block
        end
      end
    end

    it "returns the group matching the given name" do
      subject.group!("masters").name.should eql("masters")
    end

    it "raises an exception on a missing group" do
      lambda { subject.group!("slaves") }.should raise_error(MB::GroupNotFound)
    end
  end

  describe "#nodes" do
    pending
  end

  describe "#add_group" do
    pending
  end

  describe "#service" do
    subject { MB::Component }

    it "returns a Set of services" do
      component = subject.new("activemq", plugin) do
        service "masters" do
          # block
        end
      end

      component.gears(MB::Gear::Service).should be_a(Set)
    end

    it "contains each service defined" do
      component = subject.new("activemq", plugin) do
        service "masters" do
          # block
        end
      end

      component.gears(MB::Gear::Service).should have(1).item
    end

    it "does not allow duplicate services" do
      lambda do
        subject.new("activemq", plugin) do
          service "masters" do
            # block
          end

          service "masters" do
            # block
          end
        end
      end.should raise_error(MB::DuplicateGear)
    end
  end

  describe "#versioned" do
    context "when passed nothing" do
      subject {
        klass.new("component_name", plugin) do
          versioned
        end
      }

      its(:version_attribute) { should == "component_name.version" }
    end

    context "when passed an attribute name" do
      subject {
        klass.new("versioned_component", plugin) do
          versioned_with "my.custom.attribute"
        end
      }

      its(:version_attribute) { should == "my.custom.attribute" }
    end
  end
end
