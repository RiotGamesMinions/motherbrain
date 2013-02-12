module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # Manifest for bootstrapping a collection of nodes as a specified node group
    #
    # @example valid manifest structure
    #   {
    #     "activemq::master" => [
    #       "euca-10-20-37-171.eucalyptus.cloud.riotgames.com",
    #       "euca-10-20-37-172.eucalyptus.cloud.riotgames.com"
    #     ],
    #     "activemq::slave" => [
    #       "euca-10-20-37-168.eucalyptus.cloud.riotgames.com"
    #     ]
    #   }
    #
    class Manifest < MotherBrain::Manifest
      class << self
        # @param [Hash] nodes
        # @param [Provisioner::Manifest] provisioner_manifest
        #
        # @return [Bootstrap::Manifest]
        def from_provisioner(nodes, provisioner_manifest, path = nil)
          nodes = nodes.dup
          provisioner_manifest = provisioner_manifest.dup

          obj = new.tap do |bootstrap_manifest|
            provisioner_manifest.node_groups.each do |node_group|
              instance_type = node_group[:type]
              count = node_group[:count] || 1
              groups = node_group[:groups]

              groups.each do |group|
                bootstrap_manifest[group] = Array.new

                count.times do
                  instance = nodes.find { |node|
                    node[:instance_type] == instance_type
                  }

                  bootstrap_manifest[group] << instance[:public_hostname]

                  nodes.delete(instance)
                end
              end
            end
          end

          obj.path = path

          obj
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
