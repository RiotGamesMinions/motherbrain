module MotherBrain
  module Gear
    # @author Jamie Winsor <reset@riotgames.com>
    class Service < AbstractGear
      register_gear :service

      class << self
        # Finds a gear identified by name in the list of gears supplied.
        #
        # @param [Array<MB::Gear::Service>] gears
        #   the list of gears to search in
        # @param [#to_s] name
        #   the name of the gear to search for
        #
        # @return [MB::Gear::Service]
        def find(gears, name)
          gears.find { |obj| obj.name == name.to_s }
        end
      end

      # @return [String]
      attr_reader :name
      # @return [Set<Action>]
      attr_reader :actions
      # @return [MB::Component]
      attr_reader :component

      # @param [MB::Component] component
      # @param [#to_s] name
      def initialize(component, name, &block)
        @name      = name.to_s
        @component = component
        @actions   = Set.new

        if block_given?
          dsl_eval(&block)
        end
      end

      # Find and return the given action
      #
      # @param [String] name
      #
      # @raise [ActionNotFound] if there is no action of the given name defined
      #
      # @return [Gear::Action]
      def action(name)
        action = get_action(name)

        unless action
          raise ActionNotFound, "#{self.class.keyword} '#{_attributes_[:name]}' does not have the action '#{name}'"
        end

        action
      end

      # Add a new action to this Service
      #
      # @param [Service::Action] new_action
      #
      # @return [Set<Action>]
      def add_action(new_action)
        if get_action(new_action.name)
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{_attributes_[:name]}'"
        end

        actions << new_action
      end

      private

        def dsl_eval(&block)
          CleanRoom.new(self).instance_eval do
            instance_eval(&block)
          end
        end

        # @param [String] name
        def get_action(name)
          actions.find { |action| action.name == name }
        end

      # @author Jamie Winsor <reset@riotgames.com>
      # @api private
      class CleanRoom < CleanRoomBase
        # @param [String] name
        def action(name, &block)
          real_model.add_action Action.new(name, real_model.component, &block)
        end

        private

          attr_reader :component
      end

      # @author Jamie Winsor <reset@riotgames.com>
      # @api private
      class Action
        include MB::Mixin::Services

        # @return [String]
        attr_reader :name
        # @return [Set<Ridley::Node>]
        attr_reader :nodes

        # @param [String] name
        # @param [MB::Component] component
        #
        # @raise [ArgumentError] if no block is given
        def initialize(name, component, &block)
          unless block_given?
            raise ArgumentError, "block required for action '#{name}' on component '#{component.name}'"
          end

          @name      = name
          @component = component
          @block     = block
        end

        # Run this action on the specified nodes.
        #
        # @param [MB::Job] job
        #   a job to update with status
        # @param [String] environment
        #   the environment this command is being run on
        # @param [Array<Ridley::Node>]
        #   nodes the nodes to run this action on
        #
        # @return [Service::Action]
        def run(job, environment, nodes, run_chef = true)
          job.set_status("running component: #{component.name} service action: #{name} on (#{nodes.length}) nodes")

          runner = ActionRunner.new(environment, nodes)
          runner.instance_eval(&block)
          runner.send(:run, job) # TODO: make this public when ActionRunner has a clean room

          if run_chef || runner.resets.any?
            node_querier.bulk_chef_run job, nodes
          end

          self
        ensure
          runner.send(:reset, job)
        end

        private

          attr_reader :component
          attr_reader :runner
          attr_reader :block

        # @author Jamie Winsor <reset@riotgames.com>
        # @api private
        class ActionRunner
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
                futures = nodes.map { |node|
                  Celluloid::Future.new { set_node_attributes(job, node) }
                }

                futures.map(&:value)
              end

              save_nodes job

              if @environment_attributes.any?
                set_environment_attributes(job)
              end
            end

            def reset(job)
              nodes.collect do |node|
                @node_resets.each do |attribute|
                  job.set_status("Setting node attribute '#{attribute[:key]}' to '#{attribute[:value]}' on #{node.name}")
                  node.set_chef_attribute(attribute[:key], attribute[:value])
                end

                Celluloid::Future.new { node.save }
              end.map(&:value)

              if @environment_resets.any?
                env = Application.ridley.environment.find(environment)
                @environment_resets.each do |attribute|
                  job.set_status("Setting environment attribute '#{attribute[:key]}' to '#{attribute[:value]}' in #{environment}")
                  env.set_default_attribute(attribute[:key], attribute[:value])
                end
                env.save
              end
            end

            def save_nodes(job)
              if nodes.any?
                job.set_status "Saving nodes #{nodes.collect(&:name)}"
                nodes.each(&:save)
              end
            end

            def set_environment_attributes(job)
              unless env = Application.ridley.environment.find(environment)
                raise EnvironmentNotFound.new(environment)
              end

              @environment_attributes.each do |attribute|
                key, value, options = attribute[:key], attribute[:value], attribute[:options]

                if options[:toggle]
                  @environment_resets << { key: key, value: env.default_attributes.dig(key) }
                end

                job.set_status("Setting environment attribute '#{key}' to '#{value}' in #{environment}")
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

                job.set_status("Setting node attribute '#{key}' to '#{value}' on #{node.name}")
                node.set_chef_attribute(key, value)
              end
            end
        end
      end
    end
  end
end
