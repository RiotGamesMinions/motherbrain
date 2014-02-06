module MotherBrain
  module Gear
    class DynamicService < Gear::Base
      class << self

        # Parses a service, creates a new instance of DynamicService
        # and executes a Chef run to change the state of the service.
        #
        # @param service [String]
        #   a dotted string "component.service_name"
        # @param plugin [MB::Plugin]
        #   the plugin currently in use
        # @param environment [String]
        #   the environment to operate on
        # @param state [String]
        #   the state of the service to change to
        # @param options [Hash]
        # 
        # @return [MB::JobTicket]
        def change_service_state(service, plugin, environment, state, run_chef = true, options = {})
          job = Job.new(:dynamic_service_state_change)

          component, service_name = service.split('.')
          raise InvalidDynamicService.new(component, service_name) unless component && service_name
          dynamic_service = new(component, service_name)
          dynamic_service.state_change(job, plugin, environment, state, run_chef, options)
          job.report_success
          job.ticket
        rescue => ex
          job.report_failure(ex)
        ensure
          job.terminate if job && job.alive?
        end
      end

      include MB::Mixin::Services
      include MB::Mixin::Locks
      include MB::Logging

      START   = "start".freeze
      STOP    = "stop".freeze
      RESTART = "restart".freeze
      COMMON_STATES = [
        START,
        STOP,
        RESTART
      ].freeze

      # @return [String]
      attr_reader :component
      # @return [String]
      attr_reader :name

      def initialize(component, name)
        @name      = name
        @component = component
      end

      # Executes a bulk chef run on a group of nodes using the service recipe.
      # Default behavior is to set a node attribute on each individual node serially
      # and then execute the chef run.
      #
      # @param job [MB::Job]
      # @param plugin [MB::Plugin]
      #   the plugin currently in use
      # @param environment [String]
      #   the environment to execute on
      # @param state [String]
      #   the state to change the service to
      # @param options [Hash]
      #
      # @return [MB::JobTicket]
      def state_change(job, plugin, environment, state, run_chef = true, options = {})
        log.warn { 
          "Component's service state is being changed to #{state}, which is not one of #{COMMON_STATES}" 
        } unless COMMON_STATES.include?(state)

        chef_synchronize(chef_environment: environment, force: options[:force]) do
          component_object = plugin.component(component)
          service_object = component_object.get_service(name)
          group = component_object.group(service_object.service_group)
          nodes = group.nodes(environment)
          job.report_running("preparing to change the #{name} service to #{state}")

          if options[:cluster_override]
            set_environment_attribute(job, environment, service_object.service_attribute, state)
          else
            unset_environment_attribute(job, environment, service_object.service_attribute)
            set_node_attributes(job, nodes, service_object.service_attribute, state)
          end
          if run_chef
            node_querier.bulk_chef_run(job, nodes, service_object.service_recipe)
          end
        end
      end

      def node_state_change(job, plugin, node, state, run_chef = true)
        log.warn { 
          "Component's service state is being changed to #{state}, which is not one of #{COMMON_STATES}" 
        } unless COMMON_STATES.include?(state)

        component_object = plugin.component(component)
        service = component_object.get_service(name)
        set_node_attributes(job, [node], service.service_attribute, state)
        if run_chef
          node_querier.bulk_chef_run(job, [node], service.service_recipe)
        end
      end

      def remove_node_state_change(job, plugin, node, run_chef = true)
        component_object = plugin.component(component)
        service = component_object.get_service(name)

        set_node_attributes(job, [node], service.service_attribute, nil)
        if run_chef
          node_querier.bulk_chef_run(job, [node], service.service_recipe)
        end
      end

      # Finds the environment object, sets an attribute at the
      # override level, and saves the environment back to the 
      # Chef server
      #
      # @param job [MB::Job]
      #   the job to track status
      # @param environment [String]
      #   the environment being operated on
      # @param attribute_keys [Array<String>]
      #   an array of dotted paths to attribute keys
      # @param state [String]
      #   the state to set the attribute to
      #
      # @return [Boolean]
      def set_environment_attribute(job, environment, attribute_keys, state)
        chef_environment = get_chef_environment(environment)

        attribute_keys.each do |attribute_key|
          job.set_status("Setting environment attribute '#{attribute_key}' to #{state} on #{environment}")
          chef_environment.set_override_attribute(attribute_key, state)
        end
        chef_environment.save
      end

      # Finds and returns the current Chef environment
      #
      # @param environment [String]
      #
      # @return [Ridley::EnvironmentObject]
      def get_chef_environment(environment)
        chef_connection.environment.find(environment)
      end

      # Deletes an override attribute from the environment
      #
      # @param job [MB::Job]
      # @param environment [String]
      # @param attribute_keys [Array<String>]
      #
      # @return [Boolean]
      def unset_environment_attribute(job, environment, attribute_keys)
        chef_environment = get_chef_environment(environment)

        attribute_keys.each do |attribute_key|
          job.set_status("Unsetting environment attribute '#{attribute_key}' on #{environment}")
          chef_environment.delete_override_attribute(attribute_key)
        end
        chef_environment.save
      end

      # Sets a default node attribute on the provided array
      # of nodes.
      #
      # @param job [MB::Job]
      #   the job to track status
      # @param nodes [Array<Ridley::NodeObject>]
      #   the nodes being operated on
      # @param attribute_keys [Array<String>]
      #   an array of dotted paths to attribute keys
      # @param state [String]
      #   the state to set the attribute to
      #
      # @return [Boolean]
      def set_node_attributes(job, nodes, attribute_keys, state)
        nodes.concurrent_map do |node|
          node.reload
          attribute_keys.each do |attribute_key|
            job.set_status("Setting node attribute '#{attribute_key}' to #{state.nil? ? 'nil' : state} on #{node.name}")
            node.set_chef_attribute(attribute_key, state)
          end
          node.save
        end
      end
    end
  end
end
