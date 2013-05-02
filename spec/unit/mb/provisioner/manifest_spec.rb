require 'spec_helper'

describe MB::Provisioner::Manifest do
  subject { described_class.new(valid_manifest) }

  let(:plugin) {
    metadata = MB::CookbookMetadata.new {
      name "motherbrain"
      version "0.1.0"
    }

    MB::Plugin.new(metadata)
  }

  let(:activemq) { MB::Component.new('activemq', plugin) }
  let(:nginx) { MB::Component.new('nginx', plugin) }

  let(:amq_master) { MB::Group.new('master') }
  let(:amq_slave) { MB::Group.new('slave') }
  let(:nginx_master) { MB::Group.new('master') }

  let(:valid_manifest) {
    {
      provisioner: "magic",
      options: {
        image_id: "emi-1234ABCD",
        key_name: "mb",
        security_groups: ["foo", "bar"]
      },
      nodes: [
        {
          type: "m1.large",
          groups: ["activemq::master"]
        },
        {
          type: "m1.large",
          count: 2,
          groups: ["activemq::slave"]
        },
        {
          type: "m1.small",
          groups: ["nginx::master"]
        }
      ]
    }
  }

  before(:each) do
    plugin.stub(:components).and_return([activemq, nginx])
    activemq.stub(:groups).and_return([amq_master, amq_slave])
    nginx.stub(:groups).and_return([nginx_master])
  end

  its(:node_count) { should == 4 }
  its(:provisioner) { should == "magic" }

  describe "ClassMethods" do
    subject { described_class }

    describe "::validate!" do
      it "returns true if the manifest is valid" do
        subject.validate!(valid_manifest, plugin).should be_true
      end

      it "accepts a Provisioner::Manifest" do
        subject.validate!(described_class.new({ nodes: [] }), plugin).should be_true
      end

      it "raises InvalidProvisionManifest if given a non-hash value" do
        expect {
          subject.validate!(1, plugin)
        }.to raise_error(MB::InvalidProvisionManifest)
      end

      context "when manifest contains a group that is not part of the plugin" do
        before(:each) do
          plugin.stub(:has_component?).with("activemq").and_return(false)
          plugin.stub(:has_component?).with("nginx").and_return(false)
        end

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(valid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when manifest contains a group that is not part of a group" do
        before(:each) do
          activemq.stub(:has_group?).with("master").and_return(false)
        end

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(valid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when groups is not in {group}::{group} format" do
        let(:invalid_manifest) {
          {
            nodes: [
              {
                type: "m1.large",
                count: 1,
                groups: [
                  "activemq",
                  "activemq::slave"
                ]
              }
            ]
          }
        }

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(invalid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when groups is not an array" do
        let(:invalid_manifest) {
          {
            nodes: [
              {
                type: "m1.large",
                count: 1,
                groups: "activemq::slave"
              }
            ]
          }
        }

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(invalid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when type is not provided or nil" do
        let(:invalid_manifest) {
          {
            nodes: [
              {
                count: 1,
                groups: "activemq::slave"
              }
            ]
          }
        }

        it "raises an InvalidProvisionManifest error" do
          expect {
            subject.validate!(invalid_manifest, plugin)
          }.to raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when group is nil" do
        let(:invalid_manifest) {
          {
            nodes: [
              {
                type: "m1.large",
                count: 1
              }
            ]
          }
        }

        it "raises an InvalidProvisionManifest error" do
          expect {
            subject.validate!(invalid_manifest, plugin)
          }.to raise_error(MB::InvalidProvisionManifest)
        end
      end
    end
  end
end
