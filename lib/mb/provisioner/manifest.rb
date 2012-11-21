module MotherBrain
  module Provisioner
    # @author Jamie Winsor <jamie@vialstudios.com>
    #
    # @example valid manifest structure
    #   {
    #     "m1.large": {
    #       "activemq::master": 4,
    #       "activemq::slave": 2
    #     }
    #   }
    #
    class Manifest < JSONManifest
      class << self
        # Validate the given parameter contains a Hash or Manifest with a valid structure
        #
        # @param [Provisioner::Manifest] manifest
        # @param [MotherBrain::Plugin] plugin
        #
        # @raise [InvalidProvisionManifest] if the given manifest is not well formed
        def validate(manifest, plugin)
          super(manifest)

          manifest.each_pair do |instance_type, node_groups|
            unless node_groups.is_a?(Hash)
              raise InvalidProvisionManifest, "Value for instance_type needs to be a Hash. You gave: '#{node_groups}'"
            end

            node_groups.each_pair do |name, value|
              match = name.match(Plugin::NODE_GROUP_ID_REGX)
              
              unless match
                raise InvalidProvisionManifest, "Provision manifest contained an entry not in the proper format: '#{name}'. Expected: 'component::group'"
              end

              component = match[1]
              group     = match[2]

              unless plugin.has_component?(component)
                raise InvalidProvisionManifest, "Provision manifest describes the component: '#{component}' but '#{plugin.name}' does not have this component"
              end

              unless plugin.component(component).has_group?(group)
                raise InvalidProvisionManifest, "Provision manifest describes the group: '#{group}' in the component '#{component}' but that component does not have this group"
              end
            end
          end
        end
      end

      # Returns the number of nodes expected to be created by this manifest regardless of type
      #
      # @return [Integer]
      def node_count
        count = 0
        self.each_pair do |type, node_groups|
          count += node_groups.values.inject(:+)
        end

        count
      end
    end
  end
end
