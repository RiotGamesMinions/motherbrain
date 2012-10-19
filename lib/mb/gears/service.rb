module MotherBrain
  module Gear
    # @author Jamie Winsor <jamie@vialstudios.com>
    class Service < ContextualModel
      include MB::Gear
      register_gear :service

      # @return [String]
      attr_reader :name
      # @return [Set<Action>]
      attr_reader :actions

      # @param [#to_s] name
      # @param [MB::Context] context
      # @param [MB::Component] component
      def initialize(name, context, component, &block)
        super(context)

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
          raise ActionNotFound, "#{self.class.keyword} '#{self.attributes[:name]}' does not have the action '#{name}'"
        end

        action
      end
      alias_method :run_action, :action

      # Add a new action to this Service
      #
      # @param [Service::Action] new_action
      #
      # @return [Set<Action>]
      def add_action(new_action)
        unless get_action(new_action.name).nil?
          raise DuplicateAction, "Action '#{new_action.name}' already defined on service '#{self.attributes[:name]}'"
        end

        self.actions.add(new_action)
      end

      private

        attr_reader :component

        def dsl_eval(&block)
          self.attributes = CleanRoom.new(context, self, component, &block).attributes
          self
        end

        # @param [String] name
        def get_action(name)
          self.actions.find { |action| action.name == name }
        end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class CleanRoom < ContextualModel
        # @param [MB::Context] context
        # @param [MB::Service] service
        # @param [MB::Component] component
        def initialize(context, service, component, &block)
          super(context)

          @service   = service
          @component = component
          instance_eval(&block)
        end

        # @param [String] name
        def action(name, &block)
          service.add_action Action.new(context, name, component, &block)
        end

        private

          attr_reader :service
          attr_reader :component
      end

      # @author Jamie Winsor <jamie@vialstudios.com>
      # @api private
      class Action < ContextualModel
        # @return [String]
        attr_reader :name
        # @return [Set<Ridley::Node>]
        attr_reader :nodes

        # @param [String] name
        # @param [MB::Component] component
        #
        # @raise [ArgumentError] if no block is given
        def initialize(context, name, component, &block)
          unless block_given?
            raise ArgumentError, "block required for action '#{name}' on component '#{component.name}'"
          end

          super(context)
          @name      = name
          @component = component
          @block     = block
          @runner    = ActionRunner.new(context, self, component)
        end

        # Run this action on the specified nodes.
        #
        # @param [Array<Ridley::Node>] nodes the nodes to run this action on
        def run(nodes)
          @nodes = nodes
          runner.instance_eval(&block)
          chef_run(nodes)
        ensure
          runner.reset!
          return self
        end

        # Run chef on the specified nodes.
        #
        # @param [Array<Ridley::Node>] nodes the nodes to run chef on
        def chef_run(nodes)
          runner_options = {}.tap do |opts|
            opts[:nodes]    = nodes
            opts[:user]     = config.ssh_user
            opts[:keys]     = config.ssh_key if config.ssh_key
            opts[:password] = config.ssh_password if config.ssh_password
          end

          chef = ChefRunner.new(runner_options)
          chef.test!
          status, errors = chef.run

          if status == :error
            raise ChefRunFailure.new(errors)
          end
        end

        private

          attr_reader :component
          attr_reader :runner
          attr_reader :block

        # @author Jamie Winsor <jamie@vialstudios.com>
        # @api private
        class ActionRunner < ContextualModel
          include Logging

          # @return [Array<Proc>]
          attr_reader :resets

          # @param [MB::Context] context
          # @param [Gear::Action] action
          # @param [MB::Component] component
          def initialize(context, action, component)
            super(context)
            @action    = action
            @component = component
            @resets = []
          end

          # Set an environment level attribute to the given value. The key is represented
          # by a dotted path.
          #
          # @param [String] key
          # @param [Object] value
          #
          # @option options [Boolean] :toggle
          #   set this environment attribute only for a single chef run (default: false)
          def environment_attribute(key, value, options = {})
            options[:toggle] ||= false

            log.info "Setting attribute '#{key}' to '#{value}' on #{self.environment}"

            self.chef_conn.sync do
              obj = environment.find!(self.environment)

              if options[:toggle]
                original_value = obj.override_attributes.dig(key)
                if original_value
                  resets.unshift(lambda { environment_attribute(key, original_value) })
                end
              end

              obj.set_override_attribute(key, value)
              obj.save
            end
          end

          # Set a node level attribute on all nodes for this action to the given value. 
          # The key is represented by a dotted path.
          #
          # @param [String] key
          # @param [Object] value
          #
          # @option options [Boolean] :toggle
          #   set this node attribute only for a single chef run (default: false)
          def node_attribute(key, value, options = {})
            options[:toggle] ||= false

            action.nodes.each do |l_node|
              set_node_attribute(l_node, key, value, options)
            end
          end

          def reset!
            resets.each(&:call)
          end

          private

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
              log.info "Setting attribute '#{key}' to '#{value}' on #{l_node.name}"

              self.chef_conn.sync do
                obj = node.find!(l_node.name)

                if options[:toggle]
                  original_value = obj.normal_attributes.dig(key)
                  if original_value
                    resets.unshift(lambda { set_node_attribute(l_node, key, original_value) })
                  end
                end

                obj.set_attribute(key, value)
                obj.save
              end
            end

            attr_reader :action
            attr_reader :component
        end
      end
    end
  end
end
