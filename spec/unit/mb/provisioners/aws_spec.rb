require 'spec_helper'

describe MB::Provisioners::AWS do
  before(:all) do
    Fog.mock!
  end

  let(:job) { double('job') }
  before(:each) do
    job.stub(:set_status)
  end

  let(:env_name) { "mbtest" }
  let(:plugin) { double('plugin') }

  let(:manifest) do
    MB::Provisioner::Manifest.new.from_json({
      options: {
        access_key: "ABCDEFG",
        secret_key: "abcdefgh123456789",
        endpoint: "http://euca.example.com/services/Eucalyptus",
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

  let(:aws_nodes) do
    1.upto(3).collect do |n|
      Ridley::NodeResource.new(:client,
                               name: "awsnode#{n}",
                               automatic: {
                                 ec2: {
                                   instance_id: "i-ABCDEFG#{n}"
                                 }
                               })
    end
  end

  let(:euca_nodes) do
    1.upto(3).collect do |n|
      Ridley::NodeResource.new(:client,
                               name: "eucanode#{n}",
                               automatic: {
                                 eucalyptus: {
                                   instance_id: "i-EBCDEFG#{n}"
                                 }
                               })
    end
  end

  describe "#up" do
    it "does all the steps" do
      subject.should_receive(:validate_manifest_options).and_return(true)
      subject.should_receive(:create_instances).and_return(true)
      subject.should_receive(:verify_instances).and_return(true)
      subject.should_receive(:verify_ssh).and_return(true)
      subject.should_receive(:instances_as_manifest).and_return(response)
      subject.up(job, env_name, manifest, plugin, skip_bootstrap: true).should eq(response)
    end
  end

  describe "#down" do
    it "does all the steps" do
      subject.should_receive(:terminate_instances).and_return(true)
      subject.should_receive(:delete_environment).and_return(true)
      subject.down(job, env_name).should eq(true)
    end
  end

  context "with a manifest" do
    before do
      subject.manifest = manifest
      subject.job = job
      subject.fog_connection.create_key_pair('mb') rescue Fog::Compute::AWS::Error
      job.stub(:set_status)
    end

    context "auth settings" do
      context "without manifest keys" do
        before do
          ENV['EC2_ACCESS_KEY'] = ENV['EC2_SECRET_KEY'] = ENV['AWS_ACCESS_KEY'] = ENV['AWS_SECRET_KEY'] = ENV['EC2_URL'] = nil
          subject.manifest.options.delete :access_key
          subject.manifest.options.delete :secret_key
          subject.manifest.options.delete :endpoint
        end

        it "should error on access_key" do
          lambda { subject.access_key }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on secret_key" do
          lambda { subject.secret_key }.should raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on endpoint" do
          lambda { subject.secret_key }.should raise_error(MB::InvalidProvisionManifest)
        end

        context "with Euca environment variables" do
          before do
            ENV['EC2_ACCESS_KEY'] = 'EC2ABCDEFG'
            ENV['EC2_SECRET_KEY'] = 'EC2abcdefgh123456789'
            ENV['EC2_URL']        = 'http://euca2.example.com/services/Eucalyptus'
          end

          it "should get from the Euca environment variables" do
            subject.access_key.should eq('EC2ABCDEFG')
            subject.secret_key.should eq('EC2abcdefgh123456789')
            subject.endpoint.should eq('http://euca2.example.com/services/Eucalyptus')
          end
        end

        context "with AWS environment variables" do
          before do
            ENV['AWS_ACCESS_KEY'] = 'AWSABCDEFG'
            ENV['AWS_SECRET_KEY'] = 'AWSabcdefgh123456789'
            ENV['EC2_URL']        = 'http://ec2.ap-southeast-1.amazonaws.com'
          end

          it "should get from the AWS environment variables" do
            subject.access_key.should eq('AWSABCDEFG')
            subject.secret_key.should eq('AWSabcdefgh123456789')
            subject.endpoint.should eq('http://ec2.ap-southeast-1.amazonaws.com')
          end
        end
      end

      context "with manifest keys" do
        it "should get from the manifest options" do
          subject.access_key.should eq('ABCDEFG')
          subject.secret_key.should eq('abcdefgh123456789')
          subject.endpoint.should eq('http://euca.example.com/services/Eucalyptus')
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

        
    describe "#verify_ssh" do
      before do
        subject.create_instances
        subject.verify_instances
      end

      let(:instance) { double("aws_instance") }
      it "should wait for SSH" do
        Fog.should_receive(:wait_for)
        subject.verify_ssh
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

  describe "#instance_ids" do
    before do
      subject.env_name = env_name
    end

    context "AWS" do
      before do
        subject.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(aws_nodes)
      end

      it "should find 3 instances" do
        subject.instance_ids.should have(3).instances
      end

      it "should find all 3" do
        instance_ids = subject.instance_ids
        ["i-ABCDEFG1", "i-ABCDEFG2", "i-ABCDEFG3"].each do |i|
          instance_ids.should include(i)
        end
      end
    end

    context "Eucalyptus" do
      before do
        subject.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(euca_nodes)
      end

      it "should find 3 instances" do
        subject.instance_ids.should have(3).instances
      end

      it "should find all 3" do
        instance_ids = subject.instance_ids
        ["i-EBCDEFG1", "i-EBCDEFG2", "i-EBCDEFG3"].each do |i|
          instance_ids.should include(i)
        end
      end
    end
  end

  describe "#terminate_instances" do
    it "should call Fog" do
      subject.should_receive(:instance_ids).and_return(["i-ABCD1234"])
      subject.fog_connection.should_receive(:terminate_instances).with(["i-ABCD1234"])
      subject.terminate_instances
    end
  end
end
