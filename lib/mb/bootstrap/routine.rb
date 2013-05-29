module MotherBrain
  module Bootstrap
    # @author Jamie Winsor <reset@riotgames.com>
    class Routine
      # Container for a bootstrap task defined in a bootstrap routine
      #
      # @api private
      class Task
        class << self
          # Create a new bootstrap routine task from a group path
          #
          # @param [MB::Plugin] plugin
          #   the plugin to find the group in
          # @param [#to_s] group_path
          #   a string representing the path to a group in a component ("nginx::master")
          #
          # @raise [MB::PluginSyntaxError] if the group or component is not found on the plugin
          #
          # @return [Routine::Task]
          def from_group_path(plugin, group_path)
            component_id, group_id = group_path.to_s.split('::')
            group                  = plugin.component!(component_id).group!(group_id)
            from_group(group_path, group)
          rescue ComponentNotFound, GroupNotFound => ex
            raise PluginSyntaxError, ex
          end

          # @param [#to_s] group_path
          #   a string representing the path to a group in a component ("nginx::master")
          # @param [MB::Group] group
          #
          # @return [Routine::Task]
          def from_group(group_path, group)
            new(group_path, run_list: group.run_list, chef_attributes: group.chef_attributes)
          end
        end

        # @return [String]
        attr_reader :group_name
        # @return [Array]
        attr_reader :run_list
        # @return [Hashie::Mash]
        attr_reader :chef_attributes

        # @param [String] group_name
        def initialize(group_name, options = {})
          @group_name      = group_name
          @run_list        = options[:run_list] || Array.new
          @chef_attributes = options[:chef_attributes] || Hashie::Mash.new
        end
      end

      class << self
        # Takes a task, or array of tasks, and a Bootstrap::Manifest and returns a Hash containing instructions
        # for how to bootstrap each node found in the manifest based on the set of tasks, or task, given.
        #
        # @param [Bootstrap::Routine::Task, Array<Bootstrap::Routine::Task>] tasks
        # @param [Bootstrap::Manifest] manifest
        #
        # @return [Hash]
        #   A hash containing an entry for every host to bootstrap and the groups it belongs to, the
        #   run list it should be bootstrapped with, and the chef attributes to be applied to the node
        #   for it's first run.
        #
        #   {
        #     "euca-10-20-37-171.eucalyptus.cloud.riotgames.com" => {
        #       groups: [ "app_server::default" ],
        #       options: {
        #         run_list: Array.new,
        #         chef_attributes: Hashie::Hash.new
        #       }
        #     },
        #     "euca-10-20-37-172.eucalyptus.cloud.riotgames.com" => {
        #       groups: [ "app_server::default", "database_slave::default" ],
        #       options: {
        #         run_list: Array.new,
        #         chef_attributes: Hashie::Hash.new
        #       }
        #     },
        #     "euca-10-20-37-168.eucalyptus.cloud.riotgames.com" => {
        #       groups: [ "database_master::default" ],
        #       options: {
        #         run_list: Array.new,
        #         chef_attributes: Hashie::Hash.new
        #       }
        #     }
        #   }
        def map_instructions(tasks, manifest)
          {}.tap do |nodes|
            Array(tasks).each do |task|
              manifest.hosts_for_group(task.group_name).each do |host|
                nodes[host] ||= {
                  groups: Array.new,
                  options: {
                    run_list: Array.new,
                    chef_attributes: Hashie::Mash.new
                  }
                }

                nodes[host][:groups] << task.group_name unless nodes[host][:groups].include?(task.group_name)
                nodes[host][:options][:run_list]        = nodes[host][:options][:run_list] | task.run_list
                nodes[host][:options][:chef_attributes] =
                  nodes[host][:options][:chef_attributes].deep_merge(task.chef_attributes)
              end
            end
          end
        end
      end

      # @return [MB::Plugin]
      attr_reader :plugin

      # @param [MB::Plugin] plugin
      def initialize(plugin, &block)
        @plugin     = plugin
        @task_procs = Array.new

        if block_given?
          dsl_eval(&block)
        end
      end

      # Returns an array of groups or an array of an array groups representing the order in
      # which the cluster should be bootstrapped in. Groups which can be bootstrapped together
      # are contained within an array. Groups should be bootstrapped starting from index 0 of
      # the returned array.
      #
      # @return [Array<Bootstrap::Routine::Task>, Array<Array<Bootstrap::Routine::Task>>]
      def task_queue
        @task_queue ||= MB.expand_procs(task_procs)
      end

      # Checks if the routine contains a boot task for the given node group
      #
      # @param [String] node_group
      #   name for a bootstrap task to check for
      #
      # @return [Boolean]
      def has_task?(node_group, task_queue = self.task_queue)
        task_queue.find do |task|
          if task.is_a?(Array)
            has_task?(node_group, task)
          else
            task.group_name == node_group
          end
        end
      end

      private

        # @return [Array<Proc>]
        attr_reader :task_procs

        def dsl_eval(&block)
          room = CleanRoom.new(self)
          room.instance_eval(&block)
          @task_procs = room.send(:task_procs)
        end

      # @author Jamie Winsor <reset@riotgames.com>
      # @api private
      class CleanRoom < CleanRoomBase
        # Add a Bootstrap::Routine::Task for bootstrapping nodes in the given node group to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     bootstrap("mysql::master")
        #   end
        #
        # @param [String] group_path
        #   a group path
        def bootstrap(group_path)
          self.task_procs.push -> { Task.from_group_path(real_model.plugin, group_path) }
        end

        # Add an array of Bootstrap::Routine::Task(s) to be executed asyncronously to the {Routine}
        #
        # @example
        #   Routine.new(...) do
        #     async do
        #       bootstrap("mysql::master")
        #       bootstrap("myapp::webserver")
        #     end
        #   end
        def async(&block)
          room = self.class.new(real_model)
          room.instance_eval(&block)

          self.task_procs.push room.task_procs
        end

        protected

          # @return [Array<Proc>]
          def task_procs
            @task_procs ||= Array.new
          end
      end
    end
  end
end
