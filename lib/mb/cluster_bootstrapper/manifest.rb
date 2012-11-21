module MotherBrain
  class ClusterBootstrapper
    # @author Jamie Winsor <jamie@vialstudios.com>
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
      end
    end
  end
end
