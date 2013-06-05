require 'spec_helper'

describe MB::Provisioner::AWS do
  subject { aws }
  let(:aws) { described_class.new }

  let(:job) { double('job') }

  before :all do
    Fog::Mock.delay = 0
    Fog.mock!
  end

  before :each do
    aws.stub :sleep
    job.stub :set_status
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
      aws.should_receive(:validate_manifest_options).and_return(true)
      aws.should_receive(:create_instances).and_return(true)
      aws.should_receive(:verify_instances).and_return(true)
      aws.should_receive(:verify_connection).and_return(true)
      aws.should_receive(:instances_as_manifest).and_return(response)
      expect(aws.up(job, env_name, manifest, plugin, skip_bootstrap: true)).to eq(response)
    end
  end

  describe "#down" do
    it "is not implemented" do
      expect {
        aws.down
      }.to raise_error(RuntimeError)
    end
  end

  context "with a manifest" do
    before do
      fog.create_key_pair('mb') rescue Fog::Compute::AWS::Error
    end

    let(:fog) { aws.send(:fog_connection, manifest) }

    context "auth settings" do
      context "without manifest keys" do
        before do
          ENV['EC2_ACCESS_KEY'] = ENV['EC2_SECRET_KEY'] = ENV['AWS_ACCESS_KEY'] = ENV['AWS_SECRET_KEY'] = ENV['EC2_URL'] = nil
          manifest.options.delete :access_key
          manifest.options.delete :secret_key
          manifest.options.delete :endpoint
        end

        it "should error on access_key" do
          expect { aws.send(:access_key, manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on secret_key" do
          expect { aws.send(:secret_key, manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "should error on endpoint" do
          expect { aws.send(:endpoint, manifest) }.to raise_error(MB::InvalidProvisionManifest)
        end

        context "with Euca environment variables" do
          before do
            ENV['EC2_ACCESS_KEY'] = 'EC2ABCDEFG'
            ENV['EC2_SECRET_KEY'] = 'EC2abcdefgh123456789'
            ENV['EC2_URL']        = 'http://euca2.example.com/services/Eucalyptus'
          end

          it "should get from the Euca environment variables" do
            expect(aws.send(:access_key, manifest)).to eq('EC2ABCDEFG')
            expect(aws.send(:secret_key, manifest)).to eq('EC2abcdefgh123456789')
            expect(aws.send(:endpoint, manifest)).to eq('http://euca2.example.com/services/Eucalyptus')
          end
        end

        context "with AWS environment variables" do
          before do
            ENV['AWS_ACCESS_KEY'] = 'AWSABCDEFG'
            ENV['AWS_SECRET_KEY'] = 'AWSabcdefgh123456789'
            ENV['EC2_URL']        = 'http://ec2.ap-southeast-1.amazonaws.com'
          end

          it "should get from the AWS environment variables" do
            expect(aws.send(:access_key, manifest)).to eq('AWSABCDEFG')
            expect(aws.send(:secret_key, manifest)).to eq('AWSabcdefgh123456789')
            expect(aws.send(:endpoint, manifest)).to eq('http://ec2.ap-southeast-1.amazonaws.com')
          end
        end
      end

      context "with manifest keys" do
        it "should get from the manifest options" do
          expect(aws.send(:access_key, manifest)).to eq('ABCDEFG')
          expect(aws.send(:secret_key, manifest)).to eq('abcdefgh123456789')
          expect(aws.send(:endpoint, manifest)).to eq('http://euca.example.com/services/Eucalyptus')
        end
      end
    end

    describe "#validate_manifest_options(job,manifest)" do
      subject(:validate_manifest_options) {
        aws.send(:validate_manifest_options, job, manifest)
      }

      context "with a valid options hash in the manifest" do
        it { should be_true }

        it "does not raise when SecurityGroups is not set" do
          manifest[:options].delete :security_groups
          expect { validate_manifest_options }.not_to raise_error(MB::InvalidProvisionManifest)
        end
      end

      context "with an invalid options hash in the manifest" do
        it { should be_true }

        it "raises on no options" do
          manifest.delete :options
          expect { validate_manifest_options }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no ImageId" do
          manifest[:options].delete :image_id
          expect { validate_manifest_options }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no KeyName" do
          manifest[:options].delete :key_name
          expect { validate_manifest_options }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on no AvailabilityZone" do
          manifest[:options].delete :availability_zone
          expect { validate_manifest_options }.to raise_error(MB::InvalidProvisionManifest)
        end

        it "raises on SecurityGroups not being an array" do
          manifest[:options][:security_groups] = :fleeble
          expect { validate_manifest_options }.to raise_error(MB::InvalidProvisionManifest)
        end
      end
    end

    context "ssh configuration" do
      context "set in manifest" do
        before do
          manifest[:options][:ssh] ||= {}
          manifest[:options][:ssh][:user] = "dauser"
          manifest[:options][:ssh][:keys] = ["/home/dauser/.ssh/dakey"]
        end

        it "finds the ssh username from the manifest" do
          expect(aws.send(:ssh_username, manifest.options)).to eq("dauser")
        end

        it "finds the ssh keys from the manifest" do
          expect(aws.send(:ssh_keys, manifest.options).first).to eq("/home/dauser/.ssh/dakey")
        end
      end

      context "not set in manifest" do
        before do
          manifest[:options].delete(:ssh)
        end

        context "set in config" do
          before do
            MB::Application.config[:ssh] ||= {}
            MB::Application.config[:ssh][:user] = "dauser2"
            MB::Application.config[:ssh][:keys] = ["/home/dauser2/.ssh/dakey"]
          end

          it "finds the ssh username from the config" do
            expect(aws.send(:ssh_username, manifest.options)).to eq("dauser2")
          end

          it "finds the ssh keys from the config" do
            expect(aws.send(:ssh_keys, manifest.options).first).to eq("/home/dauser2/.ssh/dakey")
          end
        end

        context "not set in config" do
          before do
            MB::Application.config[:ssh] = nil
          end

          it "fails when trying to find the ssh username" do
            expect { aws.send(:ssh_username, manifest.options) }.to raise_error(MB::InvalidProvisionManifest)
          end

          it "fails when trying to find the ssh keys" do
            expect { aws.send(:ssh_keys, manifest.options) }.to raise_error(MB::InvalidProvisionManifest)
          end
        end
      end
    end

    describe "#instance_counts" do
      subject(:instance_counts) { aws.send(:instance_counts, manifest) }

      it { should be_a(Hash) }

      it "counts the m1.large instances" do
        expect(instance_counts['m1.large']).to eq(6)
      end

      it "counts the m1.small instances" do
        expect(instance_counts['m1.small']).to eq(2)
      end
    end

    describe "#create_instances" do
      it "makes calls by instance type" do
        aws.should_receive(:run_instances).exactly(2).times.and_return(true)
        aws.send :create_instances, job, manifest, fog
      end
    end

    describe "#run_instances" do
      it "keeps track of the instances" do
        result = aws.send(:run_instances, job, fog, {}, "m1.large", 3, manifest.options)

        expect(result).to be_a(Hash)
        expect(result).to have(3).instances

        result.each do |type, instance|
          expect(instance[:type]).to eq("m1.large")
          expect(instance[:ipaddress]).to be_nil
        end
      end
    end

    describe "#verify_instances" do
      it "should check the instance status" do
        instances = aws.send(:create_instances, job, manifest, fog)
        fog.should_receive(:describe_instances).and_call_original
        aws.send :verify_instances, job, fog, instances
      end
    end


    describe "#verify_connection" do
      it "should wait for SSH" do
        instances = aws.send(:create_instances, job, manifest, fog)
        aws.send :verify_instances, job, fog, instances
        Fog.should_receive(:wait_for)
        aws.send :verify_connection, job, fog, manifest, instances
      end
    end

    describe "#instances_as_manifest" do
      let(:instances) { aws.send(:create_instances, job, manifest, fog) }

      before do
        instances.each do |instance_id, instance|
          instance[:ipaddress] = "172.16.1.#{rand(253)+1}"
          instance[:status]    = 16
        end
      end

      it "returns an array" do
        expect(aws.send(:instances_as_manifest, instances)).to be_an(Array)
      end

      it "has 8 instances" do
        expect(aws.send(:instances_as_manifest, instances)).to have(8).instances
      end
    end
  end

  describe "#instance_ids" do
    subject(:instance_ids) { aws.send(:instance_ids, env_name) }

    context "AWS" do
      before do
        aws.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(aws_nodes)
      end

      it { should have(3).instances }

      it "should find all 3" do
        ["i-ABCDEFG1", "i-ABCDEFG2", "i-ABCDEFG3"].each do |i|
          expect(instance_ids).to include(i)
        end
      end
    end

    context "Eucalyptus" do
      before do
        aws.ridley.should_receive(:search).with(:node, "chef_environment:#{env_name}").and_return(euca_nodes)
      end

      it { should have(3).instances }

      it "should find all 3" do
        ["i-EBCDEFG1", "i-EBCDEFG2", "i-EBCDEFG3"].each do |i|
          expect(instance_ids).to include(i)
        end
      end
    end
  end

  describe "#terminate_instances" do
    it "should call Fog" do
      fog = aws.send(:fog_connection)
      aws.should_receive(:instance_ids).and_return(["i-ABCD1234"])
      fog.should_receive(:terminate_instances).with(["i-ABCD1234"])
      aws.send(:terminate_instances, job, fog, env_name)
    end
  end
end
