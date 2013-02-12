require 'spec_helper'

describe MB::Bootstrap::Manifest do
  subject { manifest }
  let(:manifest) { described_class.new(attributes) }

  let(:attributes) {
    {
      nodes: [
        {
          groups: ["activemq::master"],
          hosts: ["amq1.riotgames.com"]
        },

        {
          groups: ["nginx::master"],
          hosts: ["nginx1.riotgames.com"]
        },
      ]
    }
  }
  describe "#hosts_for_groups" do
    subject { manifest.hosts_for_groups(groups) }

    let(:groups) { ["activemq::master"] }

    it { should == manifest[:nodes].first[:hosts] }

    context "without an array" do
      let(:groups) { "activemq::master" }

      it { should == manifest[:nodes].first[:hosts] }
    end
  end

  describe "#validate!" do
    subject(:validate!) { manifest.validate!(plugin) }

    let(:plugin) {
      metadata = MB::CookbookMetadata.new do
        name "pvpnet"
        version "1.2.3"
      end

      MB::Plugin.new(metadata) do
        component "activemq" do
          group "master"
        end

        component "nginx" do
          group "master"
        end

        cluster_bootstrap do
          bootstrap("activemq::master")
          bootstrap("nginx::master")
        end
      end
    }

    it "does not raise if the manifest is well formed and contains only node groups from the given plugin" do
      expect { validate! }.to_not raise_error
    end

    context "when manifest contains a node group that is not part of the plugin" do
      let(:attributes) {
        {
          nodes: [
            {
              groups: ["not::defined"],
              hosts: ["one.riotgames.com"]
            }
          ]
        }
      }

      it "raises an InvalidBootstrapManifest error" do
        expect {
          validate!
        }.to raise_error(
          MB::InvalidBootstrapManifest,
            "Manifest describes the node group 'not::defined' which is not found in the given routine for 'pvpnet (1.2.3)'"
        )
      end
    end

    context "when a key is not in proper node group format: '{component}::{group}'" do
      let(:attributes) {
      {
        nodes: [
          {
            groups: ["activemq"],
            hosts: ["amq1.riotgames.com"]
          },

          {
            groups: ["nginx::master"],
            hosts: ["nginx1.riotgames.com"]
          },
        ]
      }
      }

      it "raises an InvalidBootstrapManifest error" do
        expect {
          validate!
        }.to raise_error(
          MB::InvalidBootstrapManifest,
            "Manifest contained the entry: 'activemq' which is not in the proper node group format: 'component::group'"
        )
      end
    end
  end

  describe ".from_provisioner" do
    let(:manifest) {
      described_class.from_provisioner(provisioner_response, provisioner_manifest, path)
    }

    let(:provisioner_response) {
      [
        {
          instance_type: "m1.large",
          public_hostname: "euca-10-20-37-171.eucalyptus.cloud.riotgames.com"
        },
        {
          instance_type: "m1.small",
          public_hostname: "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
        },
        {
          instance_type: "m1.small",
          public_hostname: "euca-10-20-37-169.eucalyptus.cloud.riotgames.com"
        }
      ]
    }

    let(:provisioner_manifest) {
      MB::Provisioner::Manifest.new(
        {
          nodes: [
            {
              type: "m1.large",
              groups: ["activemq::master"]
            },
            {
              type: "m1.small",
              count: 2,
              groups: ["activemq::slave"]
            }
          ]
        }
      )
    }

    let(:path) { nil }

    it { should be_a(MB::Bootstrap::Manifest) }

    it "has a key for each node type from the provisioner manifest" do
      should have(2).items
      should have_key("activemq::master")
      should have_key("activemq::slave")
    end

    it "has a node item for each expected node from provisioner manifest" do
      manifest["activemq::master"].should have(1).items
      manifest["activemq::slave"].should have(2).items
    end

    context "given a value for the path argument" do
      let(:path) { '/tmp/path' }

      it "sets the path value" do
        manifest.path.should eql('/tmp/path')
      end
    end
  end

end
