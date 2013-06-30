require 'spec_helper'

describe MB::EnvironmentManager do
  subject { environment_manager }

  let(:environment_manager) { described_class.new }
  let(:environment_name) { "rspec-test" }

  describe "#async_configure" do
    let(:options) { Hash.new }

    it "asynchronously calls #configure and returns a JobRecord" do
      subject.should_receive(:async).with(:configure, kind_of(MB::Job), environment_name, options)

      subject.async_configure(environment_name, options).should be_a(MB::JobRecord)
    end
  end

  describe "#configure" do
    let!(:job) { MB::Job.new(:environment_configure) }
    let!(:ticket) { job.ticket }
    let(:options) { Hash.new }

    context "when the environment exists" do
      before { chef_environment(environment_name) }

      it "sets the job to success" do
        subject.configure(job, environment_name, options)
        expect(ticket).to be_success
      end
    end

    context "when the environment does not exist" do
      before { MB::RSpec::ChefServer.clear_data }

      it "sets the job to failure because of EnvironmentNotFound" do
        subject.configure(job, environment_name, options)
        expect(ticket).to be_failure
        expect(ticket.result).to be_a(MB::EnvironmentNotFound)
      end
    end
  end

  describe "#find" do
    before { chef_environment(environment_name) }

    it "returns a Ridley::EnvironmentObject" do
      expect(subject.find(environment_name)).to be_a(Ridley::EnvironmentObject)
    end

    context "when the environment is not present on the remote Chef server" do
      before { MB::RSpec::ChefServer.clear_data }

      it "aborts an EnvironmentNotFound error" do
        expect { subject.find(environment_name) }.to raise_error(MB::EnvironmentNotFound)
      end
    end
  end

  describe "#list" do
    before do
      chef_environment("rspec-one")
      chef_environment("rspec-two")
      chef_environment("rspec-three")
    end

    it "has an item for every environment on the Chef server +1 for _default" do
      expect(subject.list).to have(4).items
    end

    it "includes the _default environment" do
      expect(subject.list.find { |e| e.chef_id }).to_not be_nil
    end
  end

  describe "#create" do
    it "creates an environment" do
      environment_manager.create environment_name

      expect(ridley.environment.find(environment_name)).to be_true
    end
  end

  describe "#destroy" do
    before { chef_environment(environment_name) }

    it "destroys the environment" do
      environment_manager.destroy environment_name

      expect(ridley.environment.find(environment_name)).to be_nil
    end
  end

  describe "#purge_nodes" do
    before do
      chef_environment(environment_name)
      ridley.node.create(name: "test", chef_environment: environment_name)
    end

    it "removes the nodes" do
      environment_manager.purge_nodes environment_name

      expect(ridley.search(:node, "chef_environment:#{environment_name}")).to be_empty
    end

    it "does not remove nodes in other environments" do
      ridley.node.create(name: "test2", chef_environment: "other")

      environment_manager.purge_nodes environment_name

      expect(ridley.search(:node, "chef_environment:other")).to_not be_empty
    end
  end
end
