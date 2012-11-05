module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  class ClusterBootstrapper < RealModelBase
    autoload :Worker, 'mb/cluster_bootstrapper/worker'

    class << self
      # Reduce a manifest to a hash containing only key/value pairs where the initial
      # keys matched the names of the given groups
      #
      # @param [Hash] manifest
      # @param [Array<MB::Group>, MB::Group] groups
      #
      # @return [Hash]
      def manifest_reduce(manifest, groups)
        manifest.select do |scoped_group, nodes|
          component_name, group_name = scoped_group.split('::')

          Array(groups).find do |group|
            group.name == group_name && group.component.name == component_name
          end
        end
      end

      # Validate the given bootstrap manifest hash
      #
      # @param [Hash] manifest
      # @param [MB::Plugin] plugin
      #
      # @raise [InvalidBootstrapManifest]
      #
      # @return [Boolean]
      def validate_manifest(manifest, plugin)
        manifest.keys.each do |scoped_group|
          component, group = scoped_group.split('::')

          unless plugin.has_component?(component)
            raise InvalidBootstrapManifest, "Manifest describes the component: '#{component}' but '#{plugin.name}' does not have this component"
          end

          unless plugin.component(component).has_group?(group)
            raise InvalidBootstrapManifest, "Manifest describes the group: '#{group}' in the component '#{component}' but the component does not have this group"
          end
        end

        true
      end
    end

    # @return [MB::Plugin]
    attr_reader :plugin

    # @param [MB::Context] context
    # @param [MB::Plugin] plugin
    def initialize(context, plugin, &block)
      super(context)
      @plugin = plugin
      @task_procs = Array.new

      if block_given?
        dsl_eval(&block)
      end
    end

    # Bootstrap every item in the {#boot_queue} in order
    #
    # @param [Hash] manifest
    #   a hash where the keys are node group names and the values are arrays of hostnames
    # @param [Hash] options
    #   options to pass to {#concurrent_bootstrap}
    #
    # @raise [InvalidBootstrapManifest] if the given manifest does not pass validation
    #
    # @return [Array<Hash>]
    #   an array containing hashes from each item in the boot_queue. The hashes contain
    #   keys for bootstrapped node groups and values that are the Ridley::SSH::ResultSet
    #   which contains the result of bootstrapping each node.
    def run(manifest, options = {})
      self.class.validate_manifest(manifest, self.plugin)

      responses = Array.new

      until boot_queue.empty?
        reduced_manifest = self.class.manifest_reduce(manifest, boot_queue.shift)
        responses.push concurrent_bootstrap(reduced_manifest, options)
      end

      responses
    end

    # Returns an array of groups or an array of an array groups representing the order in 
    # which the cluster should be bootstrapped in. Groups which can be bootstrapped together
    # are contained within an array. Groups should be bootstrapped starting from index 0 of
    # the returned array.
    #
    # @return [Array<Group>, Array<Array<Group>>]
    def boot_queue
      @boot_queue ||= expand_procs(task_procs)
    end

    # Concurrently bootstrap a grouped collection of nodes from a manifest and return
    # their results. This function will block until all nodes have finished
    # bootstrapping.
    #
    # @param [Hash] manifest
    #   a hash where the keys are node group names and the values are arrays of hostnames
    # @param [Hash] options
    #   options to pass to a {ClusterBootstrapper::Worker}
    #
    # @return [Hash]
    #   a hash where keys are group names and their values are their Ridley::SSH::ResultSet
    def concurrent_bootstrap(manifest, options = {})
      workers = Array.new
      options[:server_url] ||= context.chef_conn.server_url

      workers = manifest.collect do |group_name, nodes|
        Worker.new(group_name, nodes, options)
      end

      futures = workers.collect do |worker|
        [
          worker.group_name,
          worker.future.run
        ]
      end

      {}.tap do |response|
        futures.each do |future|
          response[future[0]] = future[1].value
        end
      end
    ensure
      workers.map(&:terminate)
    end

    private

      attr_reader :task_procs

      def dsl_eval(&block)
        room = CleanRoom.new(context, self)
        room.instance_eval(&block)
        @task_procs = room.send(:task_procs)
      end

      def expand_procs(task_procs)
        task_procs.map! do |task_proc|
          if task_proc.is_a?(Array)
            expand_procs(task_proc)
          else
            task_proc.call
          end
        end
      end

    # @author Jamie Winsor <jamie@vialstudios.com>
    # @api private
    class CleanRoom < CleanRoomBase
      # @param [MB::Context] context
      # @param [MB::Plugin, MB::Component] real_model
      def initialize(context, real_model)
        super(context, real_model)
        @task_procs = Array.new
      end

      def bootstrap(component, group)
        self.task_procs.push lambda {
          real_model.plugin.component!(component).group!(group) 
        }
      end

      def async(&block)
        room = self.class.new(context, real_model)
        room.instance_eval(&block)

        self.task_procs.push room.task_procs
      end

      protected

        attr_reader :task_procs
    end
  end
end
