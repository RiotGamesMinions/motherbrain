module MotherBrain
  module Gear
    class Service
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
          job.set_status("Running component: #{component.name} service action: #{name} on #{nodes.collect(&:name).join(', ')}")

          runner = Service::ActionRunner.new(environment, nodes)
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
      end
    end
  end
end
