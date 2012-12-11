require 'spec_helper'

describe MB::Command do
  let(:scope) { double('plugin') }

  describe "ClassMethods" do
    subject { MB::Command }

    describe "::new" do
      before(:each) do
        @command = subject.new("start", scope) do
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

  subject do
    described_class.new("start", scope) do
      description "start all services"
      execute do; true; end
    end
  end

  describe "#invoke" do
    it "raises an EnvironmentNotFound error if the environment does not exist" do
      MB::Application.stub_chain(:ridley, :server_url)
      MB::Application.stub_chain(:ridley, :environment, :find).with("production").and_return(nil)

      expect {
        subject.invoke("production")
      }.to raise_error(MB::EnvironmentNotFound)
    end
  end
end
