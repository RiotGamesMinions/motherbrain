require 'spec_helper'

describe MB::ClusterBootstrapper::Manifest do
  let(:plugin) { MB::Plugin.new(@context) }

  let(:activemq) { MB::Component.new('activemq', @context) }
  let(:nginx) { MB::Component.new('nginx', @context) }

  let(:amq_master) { MB::Group.new('master', @context) }
  let(:amq_slave) { MB::Group.new('slave', @context) }
  let(:nginx_master) { MB::Group.new('master', @context) }

  before(:each) do
    plugin.stub(:components).and_return([activemq, nginx])
    activemq.stub(:groups).and_return([amq_master, amq_slave])
    nginx.stub(:groups).and_return([nginx_master])
  end

  subject { described_class }

  let(:provisioner_manifest) do
    {
      "m1.large" => {
        "activemq::master" => 2
      },
      "m1.small" => {
        "activemq::slave" => 1
      }
    }
  end

  let(:response) do
    [
      {
        instance_type: "m1.large",
        public_hostname: "euca-10-20-37-171.eucalyptus.cloud.riotgames.com"
      },
      {
        instance_type: "m1.large",
        public_hostname: "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
      },
      {
        instance_type: "m1.small",
        public_hostname: "euca-10-20-37-169.eucalyptus.cloud.riotgames.com"
      }
    ]
  end

  describe "::from_provisioner" do
    before(:each) do
      @result = subject.from_provisioner(response, provisioner_manifest)
    end

    it "returns a ClusterBootstrapper::Manifest" do
      @result.should be_a(MB::ClusterBootstrapper::Manifest)
    end

    it "has a key for each node type from the provisioner manifest" do
      @result.should have(2).items
      @result.should have_key("activemq::master")
      @result.should have_key("activemq::slave")      
    end

    it "has a node item for each expected node from provisioner manifest" do
      @result["activemq::master"].should have(2).items
      @result["activemq::slave"].should have(1).items
    end
  end

  describe "::validate" do
    let(:manifest) do
      {
        "activemq::master" => [
          "amq1.riotgames.com"
        ],
        "nginx::master" => [
          "nginx1.riotgames.com"
        ]
      }
    end

    it "returns true if the manifest is valid" do
      subject.validate(manifest, plugin).should be_true
    end

    context "when manifest contains a component that is not part of the plugin" do
      before(:each) do
        plugin.stub(:has_component?).with("activemq").and_return(false)
        plugin.stub(:has_component?).with("nginx").and_return(false)
      end

      it "raises an InvalidBootstrapManifest error" do
        lambda {
          subject.validate(manifest, plugin)
        }.should raise_error(MB::InvalidBootstrapManifest)
      end
    end

    context "when manifest contains a group that is not part of a component" do
      before(:each) do
        activemq.stub(:has_group?).with("master").and_return(false)
      end

      it "raises an InvalidBootstrapManifest error" do
        lambda {
          subject.validate(manifest, plugin)
        }.should raise_error(MB::InvalidBootstrapManifest)
      end
    end

    context "when a key is not in {component}::{group} format" do
      let(:manifest) do
        {
          "activemq" => [
            "amq1.riotgames.com"
          ],
          "nginx::master" => [
            "nginx1.riotgames.com"
          ]
        }
      end

      it "raises an InvalidBootstrapManifest error" do
        lambda {
          subject.validate(manifest, plugin)
        }.should raise_error(MB::InvalidBootstrapManifest)
      end
    end
  end
end
