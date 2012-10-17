require 'spec_helper'

describe MB::Component do
  let(:environment) { 'mb-test' }
  let(:chef_conn) { double('chef_conn') }

  subject do
    MB::Component.new("activemq", @context) do
      group "masters" do
        # block
      end
    end
  end

  describe "#groups" do
    subject do
      MB::Component.new("activemq", @context) do
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
      MB::Component.new("activemq", @context) do
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
      MB::Component.new("activemq", @context) do
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

  describe "#invoke" do
    pending
  end

  describe "#service" do
    subject do
      MB::Component.new("activemq", @context) do
        service "masters" do
          # block
        end
      end
    end

    it "returns a Set of services" do
      subject.services.should be_a(Set)
    end

    it "contains each service defined" do
      subject.services.should have(1).item
    end
  end
end
