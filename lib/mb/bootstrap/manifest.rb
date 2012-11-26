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
    class Manifest < JSONManifest
      class << self
        # @param [Hash] nodes
        # @param [Provisioner::Manifest] manifest
        #
        # @return [Bootstrap::Manifest]
        def from_provisioner(nodes, manifest, path = nil)
          nodes, manifest = nodes.dup, manifest.dup

          new(path).tap do |boot_manifest|
            manifest.each_pair do |instance_type, groups|
              groups.each_pair do |name, count|
                boot_manifest[name] = Array.new

                count.times do
                  instance = nodes.find { |obj| obj[:instance_type] == instance_type }
                  nodes.delete(instance)
                  boot_manifest[name] << instance[:public_hostname]
                end
              end
            end
          end
        end
      end

      # Validates that the instance of manifest describes a layout for the given routine
      #
      # @param [Bootstrap::Routine] routine
      #
      # @raise [InvalidBootstrapManifest]
      #
      # @return [self]
      def validate!(routine)
        self.keys.each do |node_group|
          match = node_group.match(Plugin::NODE_GROUP_ID_REGX)
          
          unless match
            msg = "Manifest contained the entry: '#{node_group}' which is not"
            msg << " in the proper node group format: 'component::group'"
            raise InvalidBootstrapManifest, msg
          end

          unless routine.has_task?(node_group)
            msg = "Manifest describes the node group '#{node_group}' which is not found"
            msg << " in the given routine for '#{routine.plugin}'"
            raise InvalidBootstrapManifest, msg
          end
        end

        self
      end
    end
  end
end
