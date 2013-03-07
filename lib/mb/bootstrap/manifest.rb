module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Manifest for bootstrapping a collection of nodes as a specified node group
    #
    # @example valid manifest structure
    #   {
    #     "nodes": [
    #       {
    #         "groups": ["activemq::master"],
    #         "hosts": [
    #           "euca-10-20-37-171.eucalyptus.cloud.riotgames.com",
    #           "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
    #         ]
    #       },
    #       {
    #         "groups": ["activemq::slave"],
    #         "hosts": [
    #           "euca-10-20-37-168.eucalyptus.cloud.riotgames.com"
    #          ]
    #       }
    #     ]
    #   }
    #
    class Manifest < MotherBrain::Manifest
      class << self
        # Create a new instance of {Bootstrap::Manifest} from the returning value from calling
        # {Provisioner#up} on a provisioner and the provision manifest sent to {Provisioner#up}.
        #
        # @param [Hash] nodes
        #   the result from calling {#up} on a provisioner
        # @param [Provisioner::Manifest] provisioner_manifest
        #   the manifest sent to the provisioner performing {#up}
        #
        # @return [Bootstrap::Manifest]
        def from_provisioner(nodes, provisioner_manifest, path = nil)
          nodes      = nodes.dup
          attributes = provisioner_manifest.dup

          new.tap do |boot_manifest|
            boot_manifest.path    = path
            boot_manifest[:nodes] = Array.new

            attributes.node_groups.each do |node_group|
              instance_type = node_group[:type]
              count         = node_group[:count] || 1
              groups        = node_group[:groups]
              hosts         = Set.new

              used_instances = nodes.select { |node|
                node[:instance_type] == instance_type
              }.take(count)

              used_instances.each do |used_instance|
                hosts.add(used_instance[:public_hostname])
                nodes.delete(used_instance)
              end

              boot_manifest[:nodes] << {
                groups: groups,
                hosts: hosts.to_a
              }
            end
          end
        end

        # Validates that the instance of manifest describes a layout for the given routine
        #
        # @param [Bootstrap::Manifest] manifest
        # @param [Plugin] plugin
        #
        # @raise [InvalidBootstrapManifest]
        # @raise [NoBootstrapRoutine]
        def validate!(manifest, plugin)
          unless plugin.bootstrap_routine
            raise NoBootstrapRoutine,
              "Plugin '#{plugin.name}' (#{plugin.version}) does not contain a bootstrap routine"
          end

          unless manifest[:nodes].is_a?(Array)
            msg = "Manifest should contain an array of nodes"
            raise InvalidBootstrapManifest, msg
          end

          manifest.node_groups.each do |node_group|
            groups = node_group[:groups]

            groups.each do |group|
              match = group.match(Plugin::NODE_GROUP_ID_REGX)

              unless match
                msg = "Manifest contained the entry: '#{group}' which is not"
                msg << " in the proper node group format: 'component::group'"
                raise InvalidBootstrapManifest, msg
              end

              unless plugin.bootstrap_routine.has_task?(group)
                msg = "Manifest describes the node group '#{group}' which is not found"
                msg << " in the given routine for '#{plugin}'"
                raise InvalidBootstrapManifest, msg
              end
            end
          end
        end
      end

      # Finds all hosts to be bootstrapped with a set of groups
      #
      # @return [Array] of hosts
      def hosts_for_groups(groups)
        node_groups.select { |node_group|
          (node_group[:groups] & Array(groups)).any?
        }.collect { |node_group|
          node_group[:hosts]
        }.flatten
      end

      # Validates that the instance of manifest describes a layout for the given routine
      #
      # @param [Plugin] plugin
      #
      # @raise [InvalidBootstrapManifest]
      # @raise [NoBootstrapRoutine]
      def validate!(plugin)
        self.class.validate!(self, plugin)
      end
    end
  end
end
