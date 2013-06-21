require 'active_support/inflector'
require 'fog'

module MotherBrain
  module Provisioner
    # Provisioner adapter for AWS/Eucalyptus
    class AWS < Provisioner::Base
      register_provisioner :aws, default: true

      # Provision nodes in the environment based on the contents of the given manifest
      #
      # @param [Job] job
      #   a job to track the progress of this action
      # @param [String] env_name
      #   the name of the environment to put the nodes in
      # @param [Provisioner::Manifest] manifest
      #   a manifest describing the way the environment should look
      # @param [Plugin] plugin
      #
      # @raise [MB::AWSProvisionError]
      #   if a caught error occurs during provisioning
      #
      # @return [Array<Hash>]
      def up(job, env_name, manifest, plugin, options = {})
        job.set_status "Starting provision"
        fog = fog_connection(manifest)
        validate_manifest_options(job, manifest)
        instances = create_instances(job, manifest, fog)
        store_provision_data job, env_name, instances_as_manifest(instances)
        verified_instances = verify_instances(job, fog, instances)
        verify_connection(job, fog, manifest, verified_instances)
        instances_as_manifest(verified_instances)
      end

      # Terminate instances for the given environment
      #
      # @param [Job] job
      #   a job to track the progress of this action
      # @param [String] environment
      # @param [Hash] options
      def down(job, environment, options = {})
        job.set_status "Searching for instances to terminate"
        instance_ids = instance_ids_for_environment(environment)

        terminate_instance_ids job, instance_ids
        remove_provision_data job, environment, instance_ids
      end

      private

        # Given an environment, return the instance IDs for either Eucalyptus
        # or Amazon EC2.
        #
        # @param [String] environment
        #   The Chef environment to search for nodes in
        #
        # @return [Array(String)]
        #   The instance IDs for any cloud nodes
        def instance_ids_for_environment(environment)
          provision_data = ProvisionData.new(environment)
          instances = provision_data.instances_for_provisioner(:aws)

          instances.collect { |instance| instance[:instance_id] }
        end

        # Terminates instances by their IDs.
        #
        # @param [Job] job
        # @param [Array(String)] instance_ids
        def terminate_instance_ids(job, instance_ids)
          fog = fog_connection
          instance_count = instance_ids.count

          job.set_status "Terminating #{instance_count} #{'instance'.pluralize(instance_count)}"

          instance_ids.each do |instance_id|
            job.set_status "Terminating instance: #{instance_id}"

            begin
              fog.terminate_instances instance_id
            rescue => error
              job.set_status "Unable to terminate instance: #{instance_id}"
              log.error error
            end
          end
        end

        # Find an appropriate AWS/Euca access key
        # Will look in manifest (if provided), and common environment
        # variables used by AWS and Euca tools
        #
        # @param [Provisioner::Manifest] manifest
        #
        # @raise [MB::InvalidProvisionManifest]
        #   if keys cannot be found
        #
        # @return [String]
        def access_key(manifest = nil)
          if manifest && manifest.options[:access_key]
            manifest.options[:access_key]
          elsif ENV['AWS_ACCESS_KEY']
            ENV['AWS_ACCESS_KEY']
          elsif ENV['EC2_ACCESS_KEY']
            ENV['EC2_ACCESS_KEY']
          elsif Application.config.aws.access_key
            Application.config.aws.access_key
          else
            abort ConfigOptionMissing.new("The configuration needs a key 'access_key', or the AWS_ACCESS_KEY or EC2_ACCESS_KEY variables need to be set")
          end
        end

        # Find an appropriate AWS/Euca secret key
        # Will look in manifest (if provided), and common environment
        # variables used by AWS and Euca tools
        #
        # @param [Provisioner::Manifest] manifest
        #
        # @raise [MB::InvalidProvisionManifest]
        #   if keys cannot be found
        #
        # @return [String]
        def secret_key(manifest = nil)
          if manifest && manifest.options[:secret_key]
            manifest.options[:secret_key]
          elsif ENV['AWS_SECRET_KEY']
            ENV['AWS_SECRET_KEY']
          elsif ENV['EC2_SECRET_KEY']
            ENV['EC2_SECRET_KEY']
          elsif Application.config.aws.secret_key
            Application.config.aws.secret_key
          else
            abort ConfigOptionMissing.new("The configuration needs a key 'secret_key', or the AWS_SECRET_KEY or EC2_SECRET_KEY variables need to be set")
          end
        end

        # @param [Hash] manifest_options
        #   accesses ssh.user key from the hash
        #
        # @raise [MB::InvalidProvisionManifest]
        #   if keys cannot be found
        #
        # @return [Array]
        def ssh_username(manifest_options)
          manifest_ssh = manifest_options[:ssh] && manifest_options[:ssh][:user]
          config_ssh = Application.config[:ssh] && Application.config[:ssh][:user]
          manifest_ssh || config_ssh || abort(InvalidProvisionManifest.new("Manifest or configuration needs an `ssh` hash with a `user` key."))
        end

        # @param [Hash] manifest_options
        #   accesses ssh.keys key from the hash
        #
        # @raise [MB::InvalidProvisionManifest]
        #   if keys cannot be found
        #
        # @return [Array]
        def ssh_keys(manifest_options)
          manifest_ssh = manifest_options[:ssh] && manifest_options[:ssh][:keys]
          config_ssh = Application.config[:ssh] && Application.config[:ssh][:keys]
          manifest_ssh || config_ssh || abort(InvalidProvisionManifest.new("Manifest or configuration needs an `ssh` hash with a `keys` array."))
        end

        # Find an appropriate AWS/Euca endpoint
        # Will look in manifest (if provided), and common environment
        # variables used by AWS and Euca tools
        #
        # @param [Provisioner::Manifest] manifest
        #
        # @return [String, nil]
        def endpoint(manifest = nil)
          manifest_options = manifest ? manifest.options : {}

          manifest_options[:endpoint] ||
            ENV['EC2_URL'] ||
            Application.config.aws.endpoint
        end

        # @param [Provisioner::Manifest] manifest
        #
        # @return [Fog::Compute]
        def fog_connection(manifest = nil)
          Fog::Compute.new(
            provider: 'aws',
            aws_access_key_id: access_key(manifest),
            aws_secret_access_key: secret_key(manifest),
            endpoint: endpoint(manifest)
          )
        end

        # @param [Job] job
        # @param [Provisioner::Manifest] manifest
        #
        # @raise [MB::InvalidProvisionManifest]
        #
        # @return [Boolean]
        def validate_manifest_options(job, manifest)
          job.set_status "Validating manifest options"
          [ :image_id, :key_name, :availability_zone ].each do |key|
            unless manifest.options[key]
              abort InvalidProvisionManifest.new("The provisioner manifest options hash needs a key '#{key}' with the AWS #{key.to_s.camelize}")
            end
          end

          if manifest.options[:security_groups] && !manifest.options[:security_groups].is_a?(Array)
            abort InvalidProvisionManifest.new("The provisioner manifest options hash key 'security_groups' needs an array of security group names")
          end

          true
        end

        # @param [Provisioner::Manifest] manifest
        #
        # @return [Hash]
        def instance_counts(manifest)
          manifest[:nodes].inject({}) do |result, element|
            result[element[:type]] ||= 0
            result[element[:type]] += element[:count].to_i
            result
          end
        end

        # @param [Job] job
        # @param [Provisioner::Manifest] manifest
        # @param [AWS::Compute] fog
        #
        # @return [Hash]
        def create_instances(job, manifest, fog)
          job.set_status "Creating instances"
          instances = {}
          instance_counts(manifest).each do |instance_type, count|
            run_instances job, fog, instances, instance_type, count, manifest.options
          end
          instances
        end

        # @param [Job] job
        # @param [AWS::Compute] fog
        # @param [Hash] instances
        # @param [String] instance_type
        # @param [Fixnum] count
        #
        # @option options [String] :image_id
        # @option options [String] :availability_zone
        # @option options [String] :key_name
        #
        # @return [Hash]
        def run_instances(job, fog, instances, instance_type, count, options)
          job.set_status "Creating #{count} #{instance_type} instance#{count > 1 ? 's' : ''} on #{fog.instance_variable_get(:@host)}"
          begin
            response = fog.run_instances options[:image_id], count, count, {
              'InstanceType' => instance_type,
              'Placement.AvailabilityZone' => options[:availability_zone],
              'KeyName' => options[:key_name]
            }
            log.debug response.inspect
          rescue Fog::Compute::AWS::Error => e
            abort AWSRunInstancesError.new(e)
          end
          if response.status == 200
            response.body["instancesSet"].each do |i|
              instances[i["instanceId"]] = {type: i["instanceType"], ipaddress: nil, status: i["instanceState"]["code"]}
            end
          else
            abort AWSRunInstancesError.new(response.error)
          end
          instances
        end

        # @param [Hash] instances
        #
        # @return [Array]
        def pending_instances(instances)
          instances.select { |i,d| d[:status].to_i != 16 }.keys
        end

        # @param [Job] job
        # @param [AWS::Compute] fog
        # @param [Hash] instances
        # @param [Fixnum] tries
        #
        # @return [Hash]
        def verify_instances(job, fog, instances, tries = 45)
          if tries <= 0
            log.debug "Giving up. instances: #{instances.inspect}"
            abort AWSInstanceTimeoutError.new("giving up on instances :-(")
          end
          pending = pending_instances(instances)
          return if pending.empty?
          job.set_status "Waiting for #{pending.size} instance#{pending.size > 1 ? 's' : ''} to be ready"
          log.info "pending instances: #{pending.join(',')}"
          begin
            response = fog.describe_instances('instance-id'=> pending)
            log.debug response.inspect
            if response.status == 200 && response.body["reservationSet"]
              reserved_instances = response.body["reservationSet"].collect {|x| x["instancesSet"] }.flatten
              reserved_instances.each do |i|
                instances[i["instanceId"]][:status]    = i["instanceState"]["code"]
                instances[i["instanceId"]][:ipaddress] = i["ipAddress"]
              end
              log.debug "instances: #{instances}"
              still_pending = pending_instances(instances)
              return instances if still_pending.empty?
              sleep 10
            else
              sleep 1
            end
          rescue Fog::Compute::AWS::NotFound
            sleep 10
          end
          verify_instances(job, fog, instances, tries-1)
        end

        # @param [Job] job
        # @param [AWS::Compute] fog
        # @param [Hash] instances
        def verify_connection(job, fog, manifest, instances)
          # TODO: remember working ones, only keep checking pending ones
          # TODO: windows support
          servers = instances.collect {|i,d| fog.servers.get(i) }
          manifest_options = manifest ? manifest.options : {}
          Fog.wait_for do
            job.set_status "Waiting for instances to be SSH-able"
            servers.all? do |s|
              s.username = ssh_username(manifest_options)
              s.private_key_path = ssh_keys(manifest_options).first
              s.sshable?
            end
          end
        end

        # @param [Hash] instances
        #
        # @return [Hash]
        def instances_as_manifest(instances)
          instances.collect { |instance_id, instance|
            {
              instance_id: instance_id,
              instance_type: instance[:type],
              public_hostname: instance[:ipaddress]
            }
          }
        end

        # @param [String] env_name
        #
        # @return [Array]
        def instance_ids(env_name)
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

        def store_provision_data(job, environment_name, instances)
          job.set_status "Storing provision data"

          provision_data = ProvisionData.new(environment_name)

          provision_data.add_instances_to_provisioner :aws, instances

          provision_data.save
        end

        def remove_provision_data(job, environment_name, instance_ids)
          job.set_status "Cleaning up provision data"

          provision_data = ProvisionData.new(environment_name)

          instance_ids.each do |instance_id|
            provision_data.remove_instance_from_provisioner(
              :aws, :instance_id, instance_id
            )
          end

          provision_data.save
        end
    end
  end

  class AWSProvisionError < ProvisionError
    error_code(5200)
  end

  class AWSRunInstancesError < AWSProvisionError
    error_code(5201)
  end

  class AWSInstanceTimeoutError < AWSRunInstancesError
    error_code(5202)
  end
end
