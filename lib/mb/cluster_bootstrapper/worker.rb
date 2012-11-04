module MotherBrain
  class ClusterBootstrapper
    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class Worker
      include Celluloid
      include Celluloid::Logger

      attr_reader :group_name
      attr_reader :nodes
      attr_reader :options

      def initialize(group_name, nodes, options = {})
        @group_name = group_name
        @nodes      = nodes
        @options    = options
      end

      # @return [Array]
      def run
        if nodes && nodes.any?
          MB.log.debug "Bootstrapping group: #{group_name} [ #{nodes.join(', ')} ]"
          Ridley::Bootstrapper.new(nodes, options).run
        else
          MB.log.debug "No nodes in group: '#{group_name}'. Skipping bootstrap task"
          [ :ok, [] ]
        end
      end
    end
  end
end
