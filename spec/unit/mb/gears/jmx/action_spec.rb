require 'spec_helper'

if jruby?
  describe MB::Gear::JMX::Action do
    subject { described_class }

    describe "::new" do
      let(:port) { 9001 }
      let(:object_name) { "com.some.thing:name=thing" }

      it "should set its attributes" do
        obj = subject.new(@context, port, object_name) do |mbean|
          mbean.do_a_thing
        end

        obj.port.should == port
        obj.object_name.should == object_name
        obj.block.should be_a(Proc)
      end

      it "should be given a block" do
        lambda do
          obj = subject.new(@context, port, object_name)
        end.should raise_error(MB::ArgumentError)
      end

      it "should be given a block with 1 argument" do
        lambda do
          obj = subject.new(@context, port, object_name) do
          end
        end.should raise_error(MB::ArgumentError)
      end

      it "should complain if not on jruby" do
        subject.any_instance.stub(:jruby?).and_return(false)

        lambda do
          obj = subject.new(@context, port, object_name) do |mbean|
          end
        end.should raise_error(MB::ActionNotSupported)
      end
    end
  end
end
