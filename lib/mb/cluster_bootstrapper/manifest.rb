module MotherBrain
  class ClusterBootstrapper
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
        # @return [ClusterBootstrapper::Manifest]
        def from_provisioner(nodes, manifest)
          new.tap do |boot_manifest|
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

        # Validate the given bootstrap manifest hash
        #
        # @param [Hash] manifest
        # @param [MB::Plugin] plugin
        #
        # @raise [InvalidBootstrapManifest]
        def validate(manifest, plugin)
          manifest.keys.each do |scoped_group|
            match = scoped_group.match(Plugin::NODE_GROUP_ID_REGX)
            
            unless match
              raise InvalidBootstrapManifest, "Manifest contained an entry: '#{scoped_group}'. This is not in the proper format 'component::group'"
            end

            component = match[1]
            group     = match[2]

            unless plugin.has_component?(component)
              raise InvalidBootstrapManifest, "Manifest describes the component: '#{component}' but '#{plugin.name}' does not have this component"
            end

            unless plugin.component(component).has_group?(group)
              raise InvalidBootstrapManifest, "Manifest describes the group: '#{group}' in the component '#{component}' but the component does not have this group"
            end
          end
        end
      end
    end
  end
end
