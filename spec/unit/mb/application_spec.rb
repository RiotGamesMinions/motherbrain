require 'spec_helper'

describe MB::Application do
  describe "ClassMethods" do
    subject { described_class }

    describe "::config_srv" do
      it "returns an instance of MB::ConfigSrv" do
        subject.config_srv.should be_a(MB::ConfigSrv)
      end
    end

    describe "::provisioner_manager" do
      it "returns an instance of MB::Provisioner::Manager" do
        subject.provisioner_manager.should be_a(MB::Provisioner::Manager)
      end
    end

    describe "::bootstrap_manager" do
      it "returns an instance of MB::Bootstrap::Manager" do
        subject.bootstrap_manager.should be_a(MB::Bootstrap::Manager)
      end
    end

    describe "::node_querier" do
      it "returns an instance of MB::NodeQuerier" do
        subject.node_querier.should be_a(MB::NodeQuerier)
      end
    end

    describe "::config" do
      it "returns an instance of MB::Config" do
        subject.config.should be_a(MB::Config)
      end
    end
  end
end
