require 'spec_helper'

describe MB::Provisioners::AWS do
  before(:all) do
    Fog.mock!
  end

  let(:job) { double('job') }

  let(:manifest) do
    MB::Provisioner::Manifest.new.from_json({
      options: {
        access_key: "ABCDEFG",
        secret_key: "abcdefgh123456789",
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

  describe "#up" do
    let(:env_name) { "mbtest" }
    let(:plugin) { double('plugin') }

    before(:each) do
      job.stub(:set_status)
    end

    it "does all the steps" do
      subject.should_receive(:validate_manifest_options).and_return(true)
      subject.should_receive(:create_instances).and_return(true)
      subject.should_receive(:verify_instances).and_return(true)
      subject.should_receive(:instances_as_manifest).and_return(response)
      subject.up(job, env_name, manifest, plugin, skip_bootstrap: true).should eq(response)
    end
  end

  context "with a manifest", :focus do
    before do
      subject.manifest = manifest
      subject.job = job
      subject.fog_connection.create_key_pair('mb') rescue Fog::Compute::AWS::Error
      job.stub(:set_status)
    end

    context "access keys" do
      context "without manifest keys" do
        before do
          ENV['EC2_ACCESS_KEY'] = ENV['EC2_SECRET_KEY'] = ENV['AWS_ACCESS_KEY'] = ENV['AWS_SECRET_KEY'] = nil
          subject.manifest.options.delete :access_key
          subject.manifest.options.delete :secret_key
        end

        it "should error on access_key" do
          lambda { subject.access_key }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on secret_key" do
          lambda { subject.secret_key }.should raise_error(MB::InvalidProvisionManifest)
        end

        context "with Euca environment variables" do
          before do
            ENV['EC2_ACCESS_KEY'] = 'EC2ABCDEFG'
            ENV['EC2_SECRET_KEY'] = 'EC2abcdefgh123456789'
          end

          it "should get from the Euca environment variables" do
            subject.access_key.should eq('EC2ABCDEFG')
            subject.secret_key.should eq('EC2abcdefgh123456789')
          end
        end

        context "with AWS environment variables" do
          before do
            ENV['AWS_ACCESS_KEY'] = 'AWSABCDEFG'
            ENV['AWS_SECRET_KEY'] = 'AWSabcdefgh123456789'
          end

          it "should get from the AWS environment variables" do
            subject.access_key.should eq('AWSABCDEFG')
            subject.secret_key.should eq('AWSabcdefgh123456789')
          end
        end
      end

      context "with manifest keys" do
        it "should get from the manifest options" do
          subject.access_key.should eq('ABCDEFG')
          subject.secret_key.should eq('abcdefgh123456789')
        end
      end
    end

    describe "#validate_manifest_options" do
      context "with a valid options hash in the manifest" do
        it "returns true" do
          subject.validate_manifest_options.should eq(true)
        end
        
        it "does not raise when SecurityGroups is not set" do
          subject.manifest[:options].delete :security_groups
          lambda { subject.validate_manifest_options.should eq(true) }.should_not raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "with an invalid options hash in the manifest" do
        it "raises on no options" do
          subject.manifest.delete :options
          lambda { subject.validate_manifest_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no ImageId" do
          subject.manifest[:options].delete :image_id
          lambda { subject.validate_manifest_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no KeyName" do
          subject.manifest[:options].delete :key_name
          lambda { subject.validate_manifest_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no AvailabilityZone" do
          subject.manifest[:options].delete :availability_zone
          lambda { subject.validate_manifest_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end
        
        it "raises on SecurityGroups not being an array" do
          subject.manifest[:options][:security_groups] = :fleeble
          lambda { subject.validate_manifest_options.should eq(true) }.should raise_error(MB::InvalidProvisionManifest)
        end
      end
    end

    describe "#instance_counts" do
      it "returns a Hash" do
        subject.instance_counts.should be_a(Hash)
      end

      it "counts the m1.large instances" do
        subject.instance_counts['m1.large'].should eq(6)
      end

      it "counts the m1.small instances" do
        subject.instance_counts['m1.small'].should eq(2)
      end
    end

    describe "#create_instances" do
      it "makes calls by instance type" do
        subject.should_receive(:run_instances).exactly(2).times.and_return(true)
        subject.create_instances
      end
    end

    describe "#run_instances" do
      before(:each) do
        subject.run_instances "m1.large", 3
      end

      it "keeps track of the instances" do
        subject.instances.should be_a(Hash)
        subject.instances.should have(3).instances
        subject.instances.each {|k,i| i[:type].should eq("m1.large") }
        subject.instances.each {|k,i| i[:ipaddress].should be_nil }
      end
    end

    describe "#verify_instances" do
      context "happy path" do
        it "should check the instance status" do
          subject.create_instances
          subject.fog_connection.should_receive(:describe_instances).at_least(2).times.and_call_original
          subject.verify_instances
        end

        
      end
    end

    describe "#instances_as_manifest" do
      before do
        subject.create_instances
        subject.instances.each do |instance_id, instance|
          instance[:ipaddress] = "172.16.1.#{rand(253)+1}"
          instance[:status]    = 16
        end
      end

      it "returns an array" do
        subject.instances_as_manifest.should be_an(Array)
      end

      it "has 8 instances" do
        subject.instances_as_manifest.should have(8).instances
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
