require 'active_support/inflector'

module MotherBrain
  module Provisioners
    # @author Michael Ivey <michael.ivey@riotgames.com>
    #
    # Provisioner adapter for AWS/Eucalyptus
    #
    class AWS
      include Provisioner
      include MB::Logging
      
      register_provisioner :aws

      attr_accessor :manifest

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
        validate_options
        create_instances
        verify_instances
        instances_as_manifest
      end

      def down(job, env_name)
        abort ProvisionError.new
      end

      def options
        manifest[:options]
      end

      def validate_options
        unless options
          raise InvalidProvisionManifest,
            "The provisioner manifest needs to have a key 'options' containing a hash of AWS options."
        end

        [:image_id, :key_name, :availability_zone].each do |key|
          unless options[key]
            raise InvalidProvisionManifest,
              "The provisioner manifest options hash needs a key '#{key}' with the AWS #{key.to_s.camelize}"
          end
        end

        if options[:security_groups] && !options[:security_groups].is_a?(Array)
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
        instance_counts.each do |instance_type, count|
          run_instances instance_type, count
        end
      end

      def run_instances(instance_type, count)
        
      end
    end
  end
end

