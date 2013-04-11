require 'active_support/inflector'
require 'fog'

module MotherBrain
  module Provisioners
    # @author Michael Ivey <michael.ivey@riotgames.com>
    #
    # Provisioner adapter for AWS/Eucalyptus
    #
    class AWS
      include Provisioner
      
      register_provisioner :aws

      attr_accessor :manifest
      attr_accessor :instances
      attr_accessor :job
      attr_accessor :env_name

      def initialize
        @instances = {}
        @__tries = 5
      end

      def access_key
        if manifest && manifest.options && manifest.options[:access_key]
          manifest.options[:access_key]
        elsif ENV['AWS_ACCESS_KEY']
          ENV['AWS_ACCESS_KEY']
        elsif ENV['EC2_ACCESS_KEY']
          ENV['EC2_ACCESS_KEY']
        else
          raise InvalidProvisionManifest,
            "The provisioner manifest options hash needs a key 'access_key' or the AWS_ACCESS_KEY or EC2_ACCESS_KEY variables need to be set"
        end
      end

      def secret_key
        if manifest && manifest.options && manifest.options[:secret_key]
          manifest.options[:secret_key]
        elsif ENV['AWS_SECRET_KEY']
          ENV['AWS_SECRET_KEY']
        elsif ENV['EC2_SECRET_KEY']
          ENV['EC2_SECRET_KEY']
        else
          raise InvalidProvisionManifest,
            "The provisioner manifest options hash needs a key 'secret_key' or the AWS_SECRET_KEY or EC2_SECRET_KEY variables need to be set"
        end
      end

      # Provision nodes in the environment based on the contents of the given manifest
      #
      # @param [Job] job
      #   a job to track the progress of this action
      # @param [String] env_name
      #   the name of the environment to put the nodes in
      # @param [Provisioner::Manifest] manifest
      #   a manifest describing the way the environment should look
      #
      # @option options [Boolean] :skip_bootstrap (false) what does this even do
      #
      # @raise [MB::ProvisionError]
      #   if a caught error occurs during provisioning
      #
      # @return [Array<Hash>]
      def up(job, env_name, manifest, plugin, options = {})
        @manifest = manifest
        @job = job
        job.set_status "starting provision"
        validate_manifest_options
        create_instances
        verify_instances
        instances_as_manifest
      end

      def down(job, env_name)
        @job = job
        @env_name = env_name
        terminate_instances
        delete_environment(env_name)
      end

      def fog_connection
        @__fog_connection ||= Fog::Compute.new(:provider => 'aws',
                                               :aws_access_key_id => access_key,
                                               :aws_secret_access_key => secret_key)
      end

      def validate_manifest_options
        job.set_status "validating manifest options"
        unless manifest.options
          raise InvalidProvisionManifest,
            "The provisioner manifest needs to have a key 'options' containing a hash of AWS options."
        end

        [:image_id, :key_name, :availability_zone].each do |key|
          unless manifest.options[key]
            raise InvalidProvisionManifest,
              "The provisioner manifest options hash needs a key '#{key}' with the AWS #{key.to_s.camelize}"
          end
        end

        if manifest.options[:security_groups] && !manifest.options[:security_groups].is_a?(Array)
          raise InvalidProvisionManifest,
            "The provisioner manifest options hash key 'security_groups' needs an array of security group names"
        end

        true
      end

      def instance_counts
        manifest[:nodes].inject({}) do |result, element|
          result[element[:type]] ||= 0
          result[element[:type]] += element[:count].to_i
          result
        end
      end

      def create_instances
        job.set_status "creating instances"
        instance_counts.each do |instance_type, count|
          run_instances instance_type, count
        end
      end

      def run_instances(instance_type, count)
        job.set_status "creating #{count} #{instance_type} instance#{count > 1 ? 's' : ''}"
        response = fog_connection.run_instances manifest.options[:image_id], count, count, {
          'InstanceType' => instance_type,
          'Placement.AvailabilityZone' => manifest.options[:availability_zone],
          'KeyName' => manifest.options[:key_name]
        }
        if response.status == 200
          response.body["instancesSet"].each do |i|
            self.instances[i["instanceId"]] = {type: i["instanceType"], ipaddress: nil, status: i["instanceState"]["code"]}
          end
        else
          raise AWSRunInstancesError, response.error
        end
      end

      def pending_instances
        instances.select {|i,d| d[:status] == 0}.keys
      end

      def keep_trying?
        @__tries > 0
      end

      def next_try
        @__tries -= 1
      end

      def verify_instances
        job.set_status "waiting for instances to be ready"
        return if pending_instances.empty?
        begin
          response = fog_connection.describe_instances('instance-id'=> pending_instances)
          if response.status == 200 && response.body["instancesSet"]
            response.body["instancesSet"].each do |i|
              self.instances[i["instanceId"]][:status]    = i["instanceState"]["code"]
              self.instances[i["instanceId"]][:ipaddress] = i["ipAddress"]
            end
            return true if pending_instances.empty?
          else
            sleep 1 if keep_trying?
          end
        rescue Fog::Compute::AWS::NotFound
          sleep 1 if keep_trying?
        end
        next_try
        if keep_trying?
          verify_instances
        else
          job.set_status "giving up on instances :-("
        end
      end

      def instances_as_manifest
        instances.collect do |instance_id, instance|
          { instance_type: instance[:type], public_hostname: instance[:ipaddress] }
        end
      end

      def instance_ids
        # TODO: throw up hands if AWS and Euca nodes in same env
        nodes = ridley.search(:node, "chef_environment:#{env_name}")
        nodes.collect do |node|
          instance_id = nil
          [:ec2, :eucalyptus].each do |k|
            instance_id = node.automatic[k][:instance_id] if node.automatic.has_key?(k)
          end
          instance_id
        end
      end

      def terminate_instances
        fog_connection.terminate_instances instance_ids
      end
    end
  end

  module Errors
    class AWSProvisionError < ProvisionError
      error_code(5200)
    end

    class AWSRunInstancesError < AWSProvisionError
      error_code(5201)
    end
  end
end

