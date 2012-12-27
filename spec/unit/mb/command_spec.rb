require 'spec_helper'

describe MB::Command do
  subject { command }

  let(:command) {
    described_class.new("start", scope) do
      description "start all services"
      execute do; true; end
    end
  }

  let(:scope) { double('plugin') }

  its(:name) { should eql("start") }
  its(:description) { should eql("start all services") }
  its(:execute) { should be_a Proc }

  describe "#invoke" do
    subject(:invoke) { command.invoke(environment) }

    let(:environment) { "production" }

    context "if the environment does not exist" do
      before do
        MB::Application.stub_chain(:ridley, :server_url)
        MB::Application.stub_chain(:ridley, :environment, :find).with(environment).and_return(nil)
      end

      it "raises an EnvironmentNotFound error" do
        expect {
          invoke
        }.to raise_error(MB::EnvironmentNotFound)
      end
    end
  end
end
