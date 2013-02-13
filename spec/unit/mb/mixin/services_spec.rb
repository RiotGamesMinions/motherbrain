require 'spec_helper'

describe MB::Mixin::Services do
  subject do
    Class.new do
      include MB::Mixin::Services
    end.new
  end

  describe "#bootstrap_manager" do
    it "returns an instance of MB::Bootstrap::Manager" do
      subject.bootstrap_manager.should be_a(MB::Bootstrap::Manager)
    end
  end

  describe "#command_invoker" do
    it "returns an instance of MB::CommandInvoker" do
      subject.command_invoker.should be_a(MB::CommandInvoker)
    end
  end

  describe "#config_manager" do
    it "returns an instance of MB::ConfigManager" do
      subject.config_manager.should be_a(MB::ConfigManager)
    end
  end

  describe "#environment_manager" do
    it "returns an instance of MB::EnvironmentManager" do
      subject.environment_manager.should be_a(MB::EnvironmentManager)
    end
  end

  describe "#job_manager" do
    it "returns an instance of MB::JobManager" do
      subject.job_manager.should be_a(MB::JobManager)
    end
  end 

  describe "#provisioner_manager" do
    it "returns an instance of MB::Provisioner::Manager" do
      subject.provisioner_manager.should be_a(MB::Provisioner::Manager)
    end
  end

  describe "#node_querier" do
    it "returns an instance of MB::NodeQuerier" do
      subject.node_querier.should be_a(MB::NodeQuerier)
    end
  end

  describe "#plugin_manager" do
    it "returns an instance of MB::PluginManager" do
      subject.plugin_manager.should be_a(MB::PluginManager)
    end
  end

  describe "#provisioner_manager" do
    it "returns an instance of MB::Provisioner::Manager" do
      subject.provisioner_manager.should be_a(MB::Provisioner::Manager)
    end
  end

  describe "#upgrade_manager" do
    it "returns an instance of MB::Upgrade::Manager" do
      subject.upgrade_manager.should be_a(MB::Upgrade::Manager)
    end
  end

  describe "#ridley" do
    it "returns an instance of Ridley::Client" do
      subject.ridley.should be_a(Ridley::Client)
    end
  end
end
