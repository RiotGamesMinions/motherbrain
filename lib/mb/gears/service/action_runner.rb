module MotherBrain
  module Gear
    class Service
      # @api private
      class ActionRunner
        include MB::Mixin::Services

        attr_reader :environment
        attr_reader :nodes
        attr_reader :toggle_callbacks

        # @param [String] environment
        # @param [Array<Ridley::Node>] nodes
        def initialize(environment, nodes)
          @environment = environment
          @nodes       = Array(nodes)

          @environment_attributes = Array.new
          @node_attributes        = Array.new
          @toggle_callbacks       = Array.new
        end

        def resets
          @toggle_callbacks
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

        private

          attr_reader :component
          attr_reader :environment_attributes
          attr_reader :node_attributes

          # @todo Make this public when ActionRunner has a clean room
          def reset(job)
            toggle_callbacks.concurrent_map { |callback| callback.call(job) }
          end

          # @todo Make this public when ActionRunner has a clean room
          def run(job)
            set_node_attributes(job)
            set_environment_attributes(job)
          end

          def set_environment_attributes(job)
            return unless environment_attributes.any?

            unless env = ridley.environment.find(environment)
              raise MB::EnvironmentNotFound.new(environment)
            end

            environment_attributes.each do |attribute|
              key, value, options = attribute[:key], attribute[:value], attribute[:options]

              if options[:toggle]
                toggle_callbacks << ->(job) {
                  message = if value.nil?
                    "Toggling off environment attribute '#{key}' in #{environment}"
                  else
                    "Toggling environment attribute '#{key}' to '#{value.inspect}' on #{environment}"
                  end
                  job.set_status(message)
                  environment.set_default_attribute(key, value)
                  environment.save
                }
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
          def set_node_attributes(job)
            return if node_attributes.empty?

            nodes.concurrent_map do |node|
              node.reload

              node_attributes.each do |attribute|
                key, value, options = attribute[:key], attribute[:value], attribute[:options]

                if options[:toggle]
                  original_value = node.chef_attributes.dig(key)

                  toggle_callbacks << ->(job) {
                    message = if original_value.nil?
                      "Toggling off node attribute '#{key}' on #{node.name}"
                    else
                      "Toggling node attribute '#{key}' back to '#{original_value.inspect}' on #{node.name}"
                    end
                    job.set_status(message)
                    node.set_chef_attribute(key, original_value)
                    node.save
                  }
                end

                job.set_status("Setting node attribute '#{key}' to #{value.inspect} on #{node.name}")
                node.set_chef_attribute(key, value)
              end

              node.save
            end
          end
      end
    end
  end
end
