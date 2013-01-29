require 'spec_helper'

describe MB::Bootstrap::Manifest do
  describe "ClassMethods" do
    subject { described_class }

    describe "::from_provisioner" do
      let(:provisioner_manifest) do
        MB::Provisioner::Manifest.new(
          "m1.large" => {
            "activemq::master" => 2
          },
          "m1.small" => {
            "activemq::slave" => 1
          }
        )
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

      before(:each) do
        @result = subject.from_provisioner(response, provisioner_manifest)
      end

      it "returns a Bootstrap::Manifest" do
        @result.should be_a(MB::Bootstrap::Manifest)
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

      context "given a value for the path argument" do
        before(:each) do
          @result = subject.from_provisioner(response, provisioner_manifest, '/tmp/path')
        end

        it "sets the path value" do
          @result.path.should eql('/tmp/path')
        end
      end
    end
  end

  describe "::validate!" do
    subject do
      described_class.new(
        "activemq::master" => [
          "amq1.riotgames.com"
        ],
        "nginx::master" => [
          "nginx1.riotgames.com"
        ]
      )
    end

    let(:plugin) do
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
    end

    it "does not raise if the manifest is well formed and contains only node groups from the given plugin" do
      expect {
        subject.validate!(plugin)
      }.to_not raise_error
    end

    context "when manifest contains a node group that is not part of the plugin" do
      subject do
        described_class.new(
          "not::defined" => [
            "one.riotgames.com"
          ]
        )
      end

      it "raises an InvalidBootstrapManifest error" do
        lambda {
          subject.validate!(plugin)
        }.should raise_error(
          MB::InvalidBootstrapManifest,
          "Manifest describes the node group 'not::defined' which is not found in the given routine for 'pvpnet (1.2.3)'"
        )
      end
    end

    context "when a key is not in proper node group format: '{component}::{group}'" do
      subject do
        described_class.new(
          "activemq" => [
            "amq1.riotgames.com"
          ],
          "nginx::master" => [
            "nginx1.riotgames.com"
          ]
        )
      end

      it "raises an InvalidBootstrapManifest error" do
        lambda {
          subject.validate!(plugin)
        }.should raise_error(
          MB::InvalidBootstrapManifest,
          "Manifest contained the entry: 'activemq' which is not in the proper node group format: 'component::group'"
        )
      end
    end
  end
end
