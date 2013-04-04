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

        if action.nil?
          raise ActionNotFound, "#{self.class.keyword} '#{self._attributes_[:name]}' does not have the action '#{name}'"
        end

        action
      end

      # Add a new action to this Service
      #
      # @param [Service::Action] new_action
      #
      # @return [Set<Action>]
      def add_action(new_action)
        unless get_action(new_action.name).nil?
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{self._attributes_[:name]}'"
        end

        self.actions.add(new_action)
      end

      private

        def dsl_eval(&block)
          CleanRoom.new(self).instance_eval do
            instance_eval(&block)
          end
        end

        # @param [String] name
        def get_action(name)
          self.actions.find { |action| action.name == name }
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
        def run(job, environment, nodes)
          job.set_status("running component: #{component.name} service action: #{name} on (#{nodes.length}) nodes")

          runner = ActionRunner.new(job, environment, nodes)
          runner.instance_eval(&block)

          job.set_status("performing a chef client run on #{nodes.length} nodes")
          node_success = 0
          node_failure = 0

          responses = nodes.collect do |node|
            node_querier.future.chef_run(node.public_hostname)
          end.each do |future|
            begin
              future.value
              node_success += 1
            rescue RemoteCommandError => ex
              node_failure += 1
            end
          end

          if node_failure > 0
            raise RemoteCommandError.new("chef client run failed on #{node_failure} nodes")
          else
            job.set_status("finished chef client run on #{node_success} nodes")
          end

          self
        ensure
          runner.try(:reset)
        end

        private

          attr_reader :component
          attr_reader :runner
          attr_reader :block

        # @author Jamie Winsor <reset@riotgames.com>
        # @api private
        class ActionRunner
          include Logging

          attr_reader :job
          attr_reader :environment
          attr_reader :nodes

          # @return [Array<Proc>]
          attr_reader :resets

          # @param [String] environment
          # @param [Array<Ridley::Node>] nodes
          def initialize(job, environment, nodes)
            @job         = job
            @environment = environment
            @nodes       = Array(nodes)
            @resets      = []
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
            options[:toggle] ||= false

            job.set_status("Setting environment attribute '#{key}' to '#{value}' on #{self.environment}")
            set_environment_attribute(key, value, options)
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
            options[:toggle] ||= false

            futures = self.nodes.collect do |l_node|
              job.set_status("Setting node attribute '#{key}' to '#{value}' on #{l_node.name}")
              Celluloid::Future.new {
                set_node_attribute(l_node, key, value, options)
              }
            end.map(&:value)
          end

          def reset
            resets.each(&:call)
          end

          private

            def set_environment_attribute(key, value, options)
              Application.ridley.sync do
                obj = environment.find!(self.environment)

                if options[:toggle]
                  original_value = obj.override_attributes.dig(key)
                  resets.unshift(lambda { environment_attribute(key, original_value) })
                end

                obj.set_override_attribute(key, value)
                obj.save
              end
            end

            # Set a node level attribute on a single node to the given value.
            # The key is represented by a dotted path.
            #
            # @param [Ridley::Node] l_node the node to set the attribute on
            # @param [String] key
            # @param [Object] value
            #
            # @option options [Boolean] :toggle
            #   set this node attribute only for a single chef run (default: false)
            def set_node_attribute(l_node, key, value, options = {})
              Application.ridley.sync do
                obj = node.find!(l_node.name)

                if options[:toggle]
                  original_value = obj.normal.dig(key)
                  resets.unshift(lambda { set_node_attribute(l_node, key, original_value) })
                end

                obj.set_chef_attribute(key, value)
                obj.save
              end
            end

            attr_reader :component
        end
      end
    end
  end
end
