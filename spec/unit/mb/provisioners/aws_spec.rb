require 'spec_helper'

describe MB::Provisioners::AWS do
  let(:manifest) do
    MB::Provisioner::Manifest.new.from_json({
      options: {
        image_id: "emi-1234ABCD",
        key_name: "mb",
        security_groups: ["foo", "bar"],
        availability_zone: "riot1"                                                
      },                                                
      nodes: [
        {
          type: "m1.large",
          count: 4,
          components: ["activemq::master"]
        },
        {
          type: "m1.large",
          count: 2,
          components: ["activemq::slave"]
        },
        {
          type: "m1.small",
          count: 2,
          components: ["nginx::server"]
        }
      ]
    }.to_json)
  end

  let(:response) do
    [
     {instance_type: "m1.large", public_hostname: "ex1.cloud.example.com"},
     {instance_type: "m1.large", public_hostname: "ex2.cloud.example.com"},
     {instance_type: "m1.large", public_hostname: "ex3.cloud.example.com"},
     {instance_type: "m1.large", public_hostname: "ex4.cloud.example.com"},
     {instance_type: "m1.large", public_hostname: "ex5.cloud.example.com"},
     {instance_type: "m1.large", public_hostname: "ex6.cloud.example.com"},
     {instance_type: "m1.small", public_hostname: "ex7.cloud.example.com"},
     {instance_type: "m1.small", public_hostname: "ex8.cloud.example.com"}
    ]
  end

  describe "#up", :focus do
    let(:job) { double('job') }
    let(:env_name) { "mbtest" }
    let(:plugin) { double('plugin') }

    before(:each) do
      job.stub(:set_status)
    end

    it "does all the steps" do
      subject.should_receive(:validate_options).and_return(true)
      subject.should_receive(:run_instances).and_return(true)
      subject.should_receive(:verify_instances).and_return(true)
      subject.should_receive(:instances_as_manifest).and_return(response)
      subject.up(job, env_name, manifest, plugin, skip_bootstrap: true).should eq(response)
    end

    context "#validate_options" do
      context "with a valid options hash in the manifest" do
        before do
          subject.manifest = manifest
        end

        it "returns true" do
          subject.validate_options.should eq(true)
        end
                
        it "does not raise when SecurityGroups is not set" do
          subject.manifest[:options].delete :security_groups
          lambda { subject.validate_options.should eq(true) }.should_not raise_error(MB::InvalidProvisionManifest)
        end

      end

      context "with an invalid options hash in the manifest" do
        before do
          subject.manifest = manifest
        end

        it "raises on no options" do
          subject.manifest.delete :options
          lambda { subject.validate_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no ImageId" do
          subject.manifest[:options].delete :image_id
          lambda { subject.validate_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no KeyName" do
          subject.manifest[:options].delete :key_name
          lambda { subject.validate_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no AvailabilityZone" do
          subject.manifest[:options].delete :availability_zone
          lambda { subject.validate_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end
        
        it "raises on SecurityGroups not being an array" do
          subject.manifest[:options][:security_groups] = :fleeble
          lambda { subject.validate_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

      end
    end
  end

  describe "#down" do
    let(:job) { double('job') }
    let(:env_name) { "mbtest" }

    before(:each) do
      job.stub(:set_status)
    end

    it "sends a destroy command to environment factory with the given environment" do
      connection = double('connection')
      subject.stub(:connection) { connection }
      subject.should_receive(:destroyed?).with(env_name).and_return(true)
      connection.stub_chain(:environment, :destroy).with(env_name).and_return(Hash.new)

      subject.down(job, env_name)
    end
  end
end
