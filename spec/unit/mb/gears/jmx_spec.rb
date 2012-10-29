require 'spec_helper'

if MB.jruby?
  describe MB::Gear::Jmx do

    describe "Class" do
      subject { MB::Gear::Jmx }
      
      it "is registered with MB::Gear" do
        MB::Gear.all.should include(subject)
      end

      it "has the inferred keyword ':jmx' from it's Class name" do
        subject.keyword.should eql(:jmx)
      end
    end

    describe "#action" do
      subject { MB::Gear::Jmx.new }

      it "returns a Gear::Jmx::Action" do
        subject.action(9001, "com.some.thing:name=thing") do |mbean|
        end.should be_a(MB::Gear::Jmx::Action)
      end
    end
  end

  describe MB::Gear::Jmx::Action do
    subject { MB::Gear::Jmx::Action }

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
        end.should raise_error(MB::ArgumentError)
      end

      it "should be given a block with 1 argument" do
        lambda do 
          obj = subject.new(port, object_name) do
          end
        end.should raise_error(MB::ArgumentError)
      end

      it "should complain if not on jruby" do
        MB.stub(:jruby?).and_return(false)

        lambda do 
          obj = subject.new(port, object_name) do |mbean|
          end
        end.should raise_error(MB::ActionNotSupported)
      end
    end
  end
end
