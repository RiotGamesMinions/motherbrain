require 'spec_helper'

describe MB::Provisioner::Manifest do
  let(:plugin) { MB::Plugin.new }

  let(:activemq) { MB::Component.new('activemq') }
  let(:nginx) { MB::Component.new('nginx') }

  let(:amq_master) { MB::Group.new('master') }
  let(:amq_slave) { MB::Group.new('slave') }
  let(:nginx_master) { MB::Group.new('master') }

  before(:each) do
    plugin.stub(:components).and_return([activemq, nginx])
    activemq.stub(:groups).and_return([amq_master, amq_slave])
    nginx.stub(:groups).and_return([nginx_master])
  end

  let(:valid_manifest) do
    {
      "m1.large" => {
        "activemq::master" => 1,
        "activemq::slave" => 2
      },
      "m1.small" => {
        "nginx::master" => 1
      }
    }
  end

  describe "ClassMethods" do
    subject { described_class }

    describe "::validate" do
      it "returns true if the manifest is valid" do
        subject.validate!(valid_manifest, plugin).should be_true
      end

      it "accepts a Provisioner::Manifest" do
        subject.validate!(described_class.new, plugin).should be_true
      end

      it "raises InvalidProvisionManifest if given a non-hash value" do
        expect {
          subject.validate!(1, plugin)
        }.to raise_error(MB::InvalidProvisionManifest)
      end

      context "when manifest contains a component that is not part of the plugin" do
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

      context "when manifest contains a group that is not part of a component" do
        before(:each) do
          activemq.stub(:has_group?).with("master").and_return(false)
        end

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(valid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when a node group is not in {component}::{group} format" do
        let(:invalid_manifest) do
          {
            "m1.large" => {
              "activemq" => 1,
              "activemq::slave" => 2
            },
            "m1.small" => {
              "nginx::master" => 1
            }
          }
        end

        it "raises an InvalidProvisionManifest error" do
          lambda {
            subject.validate!(invalid_manifest, plugin)
          }.should raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "when value for instance_type is not a hash" do
        let(:invalid_manifest) do
          {
            "m1.large" => "SOME STRING"
          }
        end

        it "raises an InvalidProvisionManifest error" do
          expect {
            subject.validate!(invalid_manifest, plugin)
          }.to raise_error(MB::InvalidProvisionManifest)
        end
      end
    end
  end

  subject { described_class.new(nil, valid_manifest) }

  describe "#node_count" do
    it "returns the number of nodes expected to be created" do
      subject.node_count.should eql(4)
    end
  end
end
