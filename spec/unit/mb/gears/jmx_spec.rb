require 'spec_helper'

if MotherBrain.jruby?
  describe MotherBrain::Gear::Jmx do

    describe "Class" do
      subject { MotherBrain::Gear::Jmx }
      
      it "is registered with MotherBrain::Gear" do
        MotherBrain::Gear.all.should include(subject)
      end

      it "has the inferred keyword ':jmx' from it's Class name" do
        subject.keyword.should eql(:jmx)
      end
    end

    describe "#action" do
      subject { MotherBrain::Gear::Jmx.new }

      it "returns a Gear::Jmx::Action" do
        subject.action(9001, "com.some.thing:name=thing") do |mbean|
        end.should be_a(MotherBrain::Gear::Jmx::Action)
      end
    end
  end

  describe MotherBrain::Gear::Jmx::Action do
    subject { MotherBrain::Gear::Jmx::Action }

    describe "::new" do
      let(:port) { 9001 }
      let(:object_name) { "com.some.thing:name=thing" }

      it "should set its attributes" do
        obj = subject.new(port, object_name) do |mbean|
          mbean.do_a_thing
        end

        obj.port.should == port
        obj.object_name.should == object_name
        obj.block.should be_a(Proc)
      end

      it "should be given a block" do
        lambda do 
          obj = subject.new(port, object_name)
        end.should raise_error(MotherBrain::ArgumentError)
      end

      it "should be given a block with 1 argument" do
        lambda do 
          obj = subject.new(port, object_name) do
          end
        end.should raise_error(MotherBrain::ArgumentError)
      end

      it "should complain if not on jruby" do
        MotherBrain.stub(:jruby?).and_return(false)

        lambda do 
          obj = subject.new(port, object_name) do |mbean|
          end
        end.should raise_error(MotherBrain::ActionNotSupported)
      end
    end
  end
end
