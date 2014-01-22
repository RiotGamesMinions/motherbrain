module MotherBrain
  module Gear
    class DynamicService < Gear::Base
      class << self
        def parse_service(service)
          component, service_name = service.split('.')
          new(component, service_name)
        end
      end

      include MB::Mixin::Services
      include MB::Mixin::Locks

      DEFAULT_STATES = [
        :start,
        :stop,
        :restart
      ].freeze

      attr_reader :component
      attr_reader :name

      def initialize(component, name)
        @name      = name.to_s
        @component = component
      end

      def async_state_change(plugin, environment, state, options = {})
        job = Job.new(:dynamic_service_state_change)

        chef_synchronize(chef_environment: environment, force: options[:force]) do
          component_object = plugin.component(component)
          service_object = component_object.get_service(name)
          group = component_object.group(service_object.service_group)
          nodes = group.nodes(environment)

          job.report_running("preparing to change the #{name} service to #{state}")

          set_node_attributes(job, nodes, service_object.service_attribute, state)
          node_querier.bulk_chef_run(job, nodes, service_object.service_recipe)
        end
        job.report_success
        job.ticket
      rescue => ex
        puts ex
        job.report_failure(ex)
      ensure
        job.terminate if job && job.alive?
      end

      def set_node_attributes(job, nodes, attribute_key, state)
        nodes.concurrent_map do |node|
          node.reload
          
          job.set_status("Setting node attribute '#{attribute_key}' to #{state} on #{node.name}")
          node.set_chef_attribute(attribute_key, state)
          node.save
        end        
      end
    end
  end
end
