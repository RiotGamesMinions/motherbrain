require 'spec_helper'

describe MB::Provisioners::AWS do
  # We test a lot of the guts
  saved_private_instance_methods = MB::Provisioners::AWS.private_instance_methods
  before(:all) { MB::Provisioners::AWS.class_eval { public *saved_private_instance_methods } }
  after(:all) { MB::Provisioners::AWS.class_eval { private *saved_private_instance_methods } }

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
      Ridley::NodeObject.new(double('resource'),
        name: "awsnode#{n}",
        automatic: {
          ec2: {
            instance_id: "i-ABCDEFG#{n}"
          }
        }
      )
    end
  end

  let(:euca_nodes) do
    1.upto(3).collect do |n|
      Ridley::NodeObject.new(double('resource'),
        name: "eucanode#{n}",
        automatic: {
          eucalyptus: {
            instance_id: "i-EBCDEFG#{n}"
          }
        }
      )
    end
  end

  describe "#up" do
    it "does all the steps" do
      subject.should_receive(:validate_manifest_options).and_return(true)
      subject.should_receive(:create_instances).and_return(true)
      subject.should_receive(:verify_instances).and_return(true)
      subject.should_receive(:verify_connection).and_return(true)
      subject.should_receive(:instances_as_manifest).and_return(response)
      expect(subject.up(job, env_name, manifest, plugin, skip_bootstrap: true)).to eq(response)
    end
  end

  describe "#down" do
    it "is not implemented" do
      expect {
        subject.down
      }.to raise_error(RuntimeError)
    end
  end

  context "with a manifest" do
    before do
      fog.create_key_pair('mb') rescue Fog::Compute::AWS::Error
      job.stub(:set_status)
    end

    let(:fog) { subject.fog_connection(manifest) }

    context "auth settings" do
      context "without manifest keys" do
        before do
          ENV['EC2_ACCESS_KEY'] = ENV['EC2_SECRET_KEY'] = ENV['AWS_ACCESS_KEY'] = ENV['AWS_SECRET_KEY'] = ENV['EC2_URL'] = nil
          manifest.options.delete :access_key
          manifest.options.delete :secret_key
          manifest.options.delete :endpoint
        end

        it "should error on access_key" do
          expect { subject.access_key(manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on secret_key" do
          expect { subject.secret_key(manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on endpoint" do
          expect { subject.secret_key(manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        context "with Euca environment variables" do
          before do
            ENV['EC2_ACCESS_KEY'] = 'EC2ABCDEFG'
            ENV['EC2_SECRET_KEY'] = 'EC2abcdefgh123456789'
            ENV['EC2_URL']        = 'http://euca2.example.com/services/Eucalyptus'
          end

          it "should get from the Euca environment variables" do
            expect(subject.access_key(manifest)).to eq('EC2ABCDEFG')
            expect(subject.secret_key(manifest)).to eq('EC2abcdefgh123456789')
            expect(subject.endpoint(manifest)).to eq('http://euca2.example.com/services/Eucalyptus')
          end
        end

        context "with AWS environment variables" do
          before do
            ENV['AWS_ACCESS_KEY'] = 'AWSABCDEFG'
            ENV['AWS_SECRET_KEY'] = 'AWSabcdefgh123456789'
            ENV['EC2_URL']        = 'http://ec2.ap-southeast-1.amazonaws.com'
          end

          it "should get from the AWS environment variables" do
            expect(subject.access_key(manifest)).to eq('AWSABCDEFG')
            expect(subject.secret_key(manifest)).to eq('AWSabcdefgh123456789')
            expect(subject.endpoint(manifest)).to eq('http://ec2.ap-southeast-1.amazonaws.com')
          end
        end
      end

      context "with manifest keys" do
        it "should get from the manifest options" do
          expect(subject.access_key(manifest)).to eq('ABCDEFG')
          expect(subject.secret_key(manifest)).to eq('abcdefgh123456789')
          expect(subject.endpoint(manifest)).to eq('http://euca.example.com/services/Eucalyptus')
        end
      end
    end

    describe "#validate_manifest_options(job,manifest)" do
      context "with a valid options hash in the manifest" do
        it "returns true" do
          expect(subject.validate_manifest_options(job,manifest)).to eq(true)
        end

        it "does not raise when SecurityGroups is not set" do
          manifest[:options].delete :security_groups
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.not_to raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "with an invalid options hash in the manifest" do
        it "raises on no options" do
          manifest.delete :options
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no ImageId" do
          manifest[:options].delete :image_id
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no KeyName" do
          manifest[:options].delete :key_name
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no AvailabilityZone" do
          manifest[:options].delete :availability_zone
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on SecurityGroups not being an array" do
          manifest[:options][:security_groups] = :fleeble
          expect { subject.validate_manifest_options(job,manifest).should eq(true) }.to raise_error(MB::InvalidProvisionManifest)
        end
      end
    end

    describe "#instance_counts" do
      it "returns a Hash" do
        expect(subject.instance_counts(manifest)).to be_a(Hash)
      end

      it "counts the m1.large instances" do
        expect(subject.instance_counts(manifest)['m1.large']).to eq(6)
      end

      it "counts the m1.small instances" do
        expect(subject.instance_counts(manifest)['m1.small']).to eq(2)
      end
    end

    describe "#create_instances" do
      it "makes calls by instance type" do
        subject.should_receive(:run_instances).exactly(2).times.and_return(true)
        subject.create_instances(job, manifest, fog)
      end
    end

    describe "#run_instances" do
      it "keeps track of the instances" do
        result  = subject.run_instances job, fog, {}, "m1.large", 3, manifest.options
        expect(result).to be_a(Hash)
        expect(result).to have(3).instances
        result.each {|k,i| expect(i[:type]).to eq("m1.large") }
        result.each {|k,i| expect(i[:ipaddress]).to be_nil }
      end
    end

    describe "#verify_instances" do
      context "happy path" do
        it "should check the instance status" do
          instances = subject.create_instances job, manifest, fog
          fog.should_receive(:describe_instances).at_least(2).times.and_call_original
          subject.verify_instances job, fog, instances
        end
      end
    end


    describe "#verify_connection" do
      it "should wait for SSH" do
        instances = subject.create_instances job, manifest, fog
        subject.verify_instances job, fog, instances
        Fog.should_receive(:wait_for)
        subject.verify_connection job, fog, manifest, instances
      end
    end

    describe "#instances_as_manifest" do
      let(:instances) { subject.create_instances job, manifest, fog }

      before do
        instances.each do |instance_id, instance|
          instance[:ipaddress] = "172.16.1.#{rand(253)+1}"
          instance[:status]    = 16
        end
      end

      it "returns an array" do
        expect(subject.instances_as_manifest(instances)).to be_an(Array)
      end

      it "has 8 instances" do
        expect(subject.instances_as_manifest(instances)).to have(8).instances
      end
    end
  end

  describe "#instance_ids" do
    context "AWS" do
      before do
        subject.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(aws_nodes)
      end

      it "should find 3 instances" do
        expect(subject.instance_ids(env_name)).to have(3).instances
      end

      it "should find all 3" do
        instance_ids = subject.instance_ids(env_name)
        ["i-ABCDEFG1", "i-ABCDEFG2", "i-ABCDEFG3"].each do |i|
          expect(instance_ids).to include(i)
        end
      end
    end

    context "Eucalyptus" do
      before do
        subject.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(euca_nodes)
      end

      it "should find 3 instances" do
        expect(subject.instance_ids(env_name)).to have(3).instances
      end

      it "should find all 3" do
        instance_ids = subject.instance_ids(env_name)
        ["i-EBCDEFG1", "i-EBCDEFG2", "i-EBCDEFG3"].each do |i|
          expect(instance_ids).to include(i)
        end
      end
    end
  end

  describe "#terminate_instances" do
    it "should call Fog" do
      fog = subject.fog_connection
      subject.should_receive(:instance_ids).and_return(["i-ABCD1234"])
      fog.should_receive(:terminate_instances).with(["i-ABCD1234"])
      subject.terminate_instances job, fog, env_name
    end
  end
end
