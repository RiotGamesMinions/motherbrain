require 'spec_helper'

describe MB::DynamicInvoker do
  let(:dynamic_invoker) { Class.new(MB::DynamicInvoker) }

  describe ".fabricate" do
    it "raises an AbstractFunction error when not implemented" do
      lambda {
        dynamic_invoker.fabricate
      }.should raise_error(MB::AbstractFunction)
    end
  end

  describe ".define_command" do
    subject(:define_command) { dynamic_invoker.send :define_command, command }

    let(:command) {
      MB::Command.new(:my_command, scope) do
        execute do
          nil
        end
      end
    }

    let(:my_command) { dynamic_invoker.instance_method :my_command }

    let(:scope) { stub(MB::Plugin) }

    before do
      define_command
    end

    it "defines the command" do
      my_command.parameters.should == [[:req, :environment]]
    end

    context "with arguments" do
      let(:command) {
        MB::Command.new(:my_command, scope) do
          execute do |a|
            nil
          end
        end
      }

      it "has an extra argument" do
        my_command.parameters.should == [
          [:req, :environment],
          [:req, :a]
        ]
      end
    end
  end
end
