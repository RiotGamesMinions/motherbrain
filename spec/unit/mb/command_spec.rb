require 'spec_helper'

describe MB::Command do
  let(:scope) { double('plugin') }

  describe "ClassMethods" do
    subject { MB::Command }

    describe "::new" do
      before(:each) do
        @command = subject.new("start", @context, scope) do
          description "start all services"

          execute do
            4 + 2
          end
        end
      end

      it "assigns a name from the given block" do
        @command.name.should eql("start")
      end

      it "assigns a description from the given block" do
        @command.description.should eql("start all services")
      end

      it "assigns a Proc as the value for execute" do
        @command.execute.should be_a(Proc)
      end
    end
  end
end
