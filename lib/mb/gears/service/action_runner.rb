module MotherBrain::Gear
  class Service
    # @author Jamie Winsor <reset@riotgames.com>
    # @api private
    class ActionRunner
      include MB::Mixin::Services

      attr_reader :environment
      attr_reader :nodes

      # @param [String] environment
      # @param [Array<Ridley::Node>] nodes
      def initialize(environment, nodes)
        @environment = environment
        @nodes       = Array(nodes)

        @environment_attributes = Array.new
        @node_attributes        = Array.new
        @environment_resets     = Array.new
        @node_resets            = Array.new
      end

      # Set an environment level attribute to the given value. The key is represented
      # by a dotted path.
      #
      # @param [String] key
      # @param [Object] value
      #
      # @option options [Boolean] :toggle (false)
      #   set this environment attribute only for a single chef run
      def environment_attribute(key, value, options = {})
        options = options.reverse_merge(toggle: false)
        @environment_attributes << { key: key, value: value, options: options }
      end

      # Set a node level attribute on all nodes for this action to the given value.
      # The key is represented by a dotted path.
      #
      # @param [String] key
      # @param [Object] value
      #
      # @option options [Boolean] :toggle (false)
      #   set this node attribute only for a single chef run
      def node_attribute(key, value, options = {})
        options = options.reverse_merge(toggle: false)
        @node_attributes << { key: key, value: value, options: options }
      end

      def resets
        @node_resets | @environment_resets
      end

      private

        attr_reader :component

        # TODO: Make this public when ActionRunner has a clean room
        def run(job)
          if @node_attributes.any?
            nodes.concurrent_map do |l_node|
              set_node_attributes(job, l_node)
            end
          end

          save_nodes job

          if @environment_attributes.any?
            set_environment_attributes(job)
          end
        end

        def reset(job)
          nodes.collect do |node|
            @node_resets.each do |attribute|
              job.set_status("Setting node attribute '#{attribute[:key]}' to #{attribute[:value].inspect} on #{node.name}")
              node.set_chef_attribute(attribute[:key], attribute[:value])
            end

            Celluloid::Future.new { node.save }
          end.map(&:value)

          if @environment_resets.any?
            env = ridley.environment.find(environment)
            @environment_resets.each do |attribute|
              job.set_status("Setting environment attribute '#{attribute[:key]}' to #{attribute[:value].inspect} in #{environment}")
              env.set_default_attribute(attribute[:key], attribute[:value])
            end
            env.save
          end
        end

        def save_nodes(job)
          if nodes.any?
            job.set_status "Saving #{nodes.collect(&:name).join(', ')}"
            nodes.each(&:save)
          end
        end

        def set_environment_attributes(job)
          unless env = ridley.environment.find(environment)
            raise MB::EnvironmentNotFound.new(environment)
          end

          @environment_attributes.each do |attribute|
            key, value, options = attribute[:key], attribute[:value], attribute[:options]

            if options[:toggle]
              @environment_resets << { key: key, value: env.default_attributes.dig(key) }
            end

            job.set_status("Setting environment attribute '#{key}' to #{value.inspect} in #{environment}")
            env.set_default_attribute(key, value)
          end

          job.set_status("Saving environment #{environment}")
          env.save
        end

        # Set all node level attributes to the given node
        #
        # @param [Ridley::Job] job
        #  a job to send status updates to
        # @param [Ridley::NodeObject] node
        #   the node to set the attribute on
        def set_node_attributes(job, node)
          node.reload
          @node_attributes.each do |attribute|
            key, value, options = attribute[:key], attribute[:value], attribute[:options]

            if options[:toggle]
              @node_resets << { key: key, value: node.normal.dig(key) }
            end

            job.set_status("Setting node attribute '#{key}' to #{value.inspect} on #{node.name}")
            node.set_chef_attribute(key, value)
          end
        end
    end
  end
end
