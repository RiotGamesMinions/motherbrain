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

      def async_state_change(plugin, environment, state)
        job = Job.new(:dynamic_service_state_change)
        job.report_running("preparing to foo")

        component_object = plugin.component(component)
        service_object = component_object.get_gear(MB::Gear::Service, name)
        group = component_object.group(service_object.service_group)
        nodes = group.nodes(environment)

        set_node_attribute(job, nodes, service_object.service_attribute, state)
        node_querier.bulk_chef_run(job, nodes, service_object.service_recipe)

        job.report_success
        job.ticket
      ensure
        job.terminate if job && job.alive?
      end

      def set_node_attribute(job, nodes, attribute_key, state)
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
