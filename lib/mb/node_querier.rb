require 'net/sftp'

module MotherBrain
  class NodeQuerier

    DISABLED_RUN_LIST_ENTRY = "recipe[disabled]".freeze

    class << self
      # @raise [Celluloid::DeadActorError] if Node Querier has not been started
      #
      # @return [Celluloid::Actor(NodeQuerier)]
      def instance
        MB::Application[:node_querier] or raise Celluloid::DeadActorError, "node querier not running"
      end
    end

    extend Forwardable
    include Celluloid
    include MB::Logging
    include MB::Mixin::Locks
    include MB::Mixin::Services

    finalizer :finalize_callback

    def initialize
      log.debug { "Node Querier starting..." }
    end

    # List all of the nodes on the target Chef Server
    #
    # @return [Array<Hash>]
    def list
      chef_connection.node.all
    end

    # Run Chef on a group of nodes, and update a job status with the result
    # @param [Job] job
    # @param [Array(Ridley::NodeResource)] nodes
    #   The collection of nodes to run Chef on
    # @param [Array<String>] override_recipes
    #   An array of run list entries that will override the node's current run list
    #
    # @raise [RemoteCommandError]
    def bulk_chef_run(job, nodes, override_recipes = nil)
      job.set_status("Performing a chef client run on #{nodes.collect(&:name).join(', ')}")

      node_successes_count = 0
      node_successes = Array.new

      node_failures_count  = 0
      node_failures = Array.new

      futures = nodes.map { |node| node_querier.future(:chef_run, node.public_hostname, override_recipes: override_recipes, connector: connector_for_os(node.chef_attributes.os)) }

      futures.each do |future|
        begin
          response = future.value
          node_successes_count += 1
          node_successes << response.host
        rescue RemoteCommandError => error
          node_failures_count += 1
          node_failures << error.host
        end
      end

      if node_failures_count > 0
        abort RemoteCommandError.new("chef client run failed on #{node_failures_count} node(s) - #{node_failures.join(', ')}")
      else
        job.set_status("Finished chef client run on #{node_successes_count} node(s) - #{node_successes.join(', ')}")
      end
    end

    # Return the Chef node_name of the target host. A nil value is returned if a
    # node_name cannot be determined
    #
    # @param [String] host
    #   hostname of the target node
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo
    #
    # @return [String, nil]
    def node_name(host, options = {})
      ruby_script('node_name', host, options).split("\n").last
    rescue MB::RemoteScriptError
      # TODO: catch auth error?
      nil
    end

    # Run Chef-Client on the target host
    #
    # @param [String] host
    #
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo
    #   bootstrap with sudo
    # @option options [String] :override_recipe
    #   a recipe that will override the nodes current run list
    # @option options [Ridley::NodeObject] :node
    #   the actual node object
    # @option options [String] :connector
    #   a connector type for the chef connection to prefer
    #
    # @raise [RemoteCommandError] if an execution error occurs in the remote command
    # @raise [RemoteCommandError] if given a blank or nil hostname
    #
    # @return [Ridley::HostConnector::Response]
    def chef_run(host, options = {})
      options = options.dup

      unless host.present?
        abort RemoteCommandError.new("cannot execute a chef-run without a hostname or ipaddress")
      end

      response = if options[:override_recipes]
        override_recipes = options[:override_recipes]

        cmd_recipe_syntax = override_recipes.join(',') { |recipe| "recipe[#{recipe}]" }
        log.info { "Running Chef client with override runlist '#{cmd_recipe_syntax}' on: #{host}" }
        chef_run_response = safe_remote(host) { chef_connection.node.execute_command(host, "chef-client --override-runlist #{cmd_recipe_syntax}", connector: options[:connector]) }

        chef_run_response
      else
        log.info { "Running Chef client on: #{host}" }
        safe_remote(host) { chef_connection.node.chef_run(host, connector: options[:connector]) }
      end

      if response.error?
        log.info { "Failed Chef client run on: #{host} - #{response.stderr.chomp}" }
        abort RemoteCommandError.new(response.stderr.chomp, host)
      end

      log.info { "Completed Chef client run on: #{host}" }
      response
    rescue Ridley::Errors::HostConnectionError => ex
      log.info { "Failed Chef client run on: #{host}" }
      abort RemoteCommandError.new(ex, host)
    end

    # Place an encrypted data bag secret on the target host
    #
    # @param [String] host
    #
    # @option options [String] :secret
    #   the encrypted data bag secret of the node querier's chef conn will be used
    #   as the default key
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo
    #   bootstrap with sudo
    #
    # @raise [RemoteFileCopyError]
    #
    # @return [Ridley::HostConnector::Response]
    def put_secret(host, options = {})
      options = options.reverse_merge(secret: Application.config.chef.encrypted_data_bag_secret_path)

      if options[:secret].nil? || !File.exists?(options[:secret])
        return nil
      end

      unless host.present?
        abort RemoteCommandError.new("cannot put_secret without a hostname or ipaddress")
      end

      response = safe_remote(host) { chef_connection.node.put_secret(host, connector: options[:connector]) }

      if response.error?
        log.info { "Failed to put secret file on: #{host}" }
        return nil
      end

      log.info { "Successfully put secret file on: #{host}" }
      response
    end

    # Executes the given command on the host using the best worker
    # available for the host.
    #
    # @param [String] host
    # @param [String] command
    #
    # @return [Ridley::HostConnection::Response]
    def execute_command(host, command)

      unless host.present?
        abort RemoteCommandError.new("cannot execute command without a hostname or ipaddress")
      end

      response = safe_remote(host) { chef_connection.node.execute_command(host, command, connector: options[:connector]) }

      if response.error?
        log.info { "Failed to execute command on: #{host}" }
        abort RemoteCommandError.new(response.stderr.chomp)
      end

      log.info { "Successfully executed command on: #{host}" }
      response
    end

    # Check if the target host is registered with the Chef server. If the node does not have Chef and
    # ruby installed by omnibus it will be considered unregistered.
    #
    # @example showing a node who is registered to Chef
    #   node_querier.registered?("192.168.1.101") #=> true
    # @example showing a node who does not have ruby or is not registered to Chef
    #   node_querier.registered?("192.168.1.102") #=> false
    #
    # @param [String] host
    #   public hostname of the target node
    #
    # @return [Boolean]
    def registered?(host)
      !!registered_as(host)
    end

    # Returns the client name the target node is registered to Chef with.
    #
    # If the node does not have a client registered with the Chef server or if Chef and ruby were not installed
    # by omnibus this function will return nil.
    #
    # @example showing a node who is registered to Chef
    #   node_querier.registered_as("192.168.1.101") #=> "reset.riotgames.com"
    # @example showing a node who does not have ruby or is not registered to Chef
    #   node_querier.registered_as("192.168.1.102") #=> nil
    #
    # @param [String] host
    #   public hostname of the target node
    #
    # @return [String, nil]
    def registered_as(host)
      if (client_id = node_name(host)).nil?
        return nil
      end
      safe_remote(host) { chef_connection.client.find(client_id).try(:name) }
    end

    # Asynchronously remove Chef from a target host and purge it's client and node object from the
    # Chef server.
    #
    # @param [String] host
    #   public hostname of the target node
    #
    # @option options [Boolean] :skip_chef (false)
    #   skip removal of the Chef package and the contents of the installation
    #   directory. Setting this to true will only remove any data and configurations
    #   generated by running Chef client.
    #
    # @return [MB::JobTicket]
    def async_purge(host, options = {})
      job = Job.new(:purge_node)
      async(:purge, job, host, options)
      job.ticket
    end

    # Asynchronously disable a node to stop services @host and prevent
    # chef-client from being run on @host until @host is reenabled
    #
    # @param [String] host
    #   public hostname of the target node
    # @param [Hash] options
    #
    # @option options [Boolean] :force (false) Ignore environment lock and execute anyway.
    #
    # @return [MB::JobTicket]
    def async_disable(host, options = {})
      job = Job.new(:disable_node)
      async(:disable, job, host, options)
      job.ticket
    end

    # Asynchronously enable a node
    #
    # @param [String] host
    #   public hostname of the target node
    # @param [Hash] options
    #
    # @option options [Boolean] :force (false) Ignore environment lock and execute anyway.
    # 
    # @return [MB::JobTicket]
    def async_enable(host, options = {})
      job = Job.new(:enable_node)
      async(:enable, job, host, options)
      job.ticket
    end

    # Remove Chef from a target host and purge it's client and node object from the Chef
    # server.
    #
    # @param [MB::Job] job
    # @param [String] host
    #   public hostname of the target node
    #
    # @option options [Boolean] :skip_chef (false)
    #   skip removal of the Chef package and the contents of the installation
    #   directory. Setting this to true will only remove any data and configurations
    #   generated by running Chef client.
    def purge(job, host, options = {})
      options = options.reverse_merge(skip_chef: false)
      futures = Array.new

      job.report_running("Discovering host's registered node name")
      if node_name = registered_as(host)
        job.set_status("Host registered as #{node_name}. Destroying client and node objects.")
        futures << chef_connection.client.future(:delete, node_name)
        futures << chef_connection.node.future(:delete, node_name)
      else
        job.set_status "Could not discover the host's node name. The host may not be registered with Chef or the " +
          "embedded Ruby used to identify the node name may not be available."
      end

      job.set_status("Cleaning up the host's file system.")
      futures << chef_connection.node.future(:uninstall_chef, host, options.slice(:skip_chef, :connector))

      begin
        safe_remote(host) { futures.map(&:value) }
      rescue RemoteCommandError => e
        job.report_failure
      end

      job.report_success
    ensure
      job.terminate if job && job.alive?
    end

    # Remove explicit service state on @host and remove disabled entry
    # from run list to allow chef-client to run on @host
    #
    # @param [MB::Job] job
    # @param [String] host
    #   public hostname of the target node
    # @param [Hash] options
    #
    # @option options [Boolean] :force (false) Ignore environment lock and execute anyway.
    # 
    def enable(job, host, options = {})
      job.report_running("Discovering host's registered node name")
      node_name = registered_as(host)
      
      if !node_name
        # TODO auth could fail and cause this to throw
        job.report_failure("Could not discover the host's node name. The host may not be " +
                           "registered with Chef or the embedded Ruby used to identify the " +
                           "node name may not be available. #{host} was not enabled!")
      end
      
      job.set_status("Host registered as #{node_name}.")

      node = fetch_node(job, node_name)

      required_run_list = []
      success = false
      chef_synchronize(chef_environment: node.chef_environment, force: options[:force], job: job) do
        if node.run_list.include?(DISABLED_RUN_LIST_ENTRY)
          required_run_list = on_dynamic_services(job, node) do |dynamic_service, plugin|
            dynamic_service.remove_node_state_change(job,
                                                     plugin,
                                                     node,
                                                     false)

          end
          if !required_run_list.empty?
            self.bulk_chef_run(job, [node], required_run_list.flatten.uniq) 
          end

          node.run_list = node.run_list.reject { |r| r == DISABLED_RUN_LIST_ENTRY }
          
          if node.save
            job.set_status "#{node.name} enabled successfully."
            success = true
          else
            job.set_status "#{node.name} did not save! Disabled run_list entry was unable to be removed to the node."
          end
        else
          job.set_status("#{node.name} is not disabled. No need to enable.")
          success = true
        end
      end

      job.report_boolean(success)
    rescue MotherBrain::ResourceLocked => e
      job.report_failure e.message
    ensure
      job.terminate if job && job.alive?
    end

    # Stop services on @host and prevent chef-client from being run on
    # @host until @host is reenabled
    #
    # @param [MB::Job] job
    # @param [String] host
    #   public hostname of the target node
    # @param [Hash] options
    #
    # @option options [Boolean] :force (false) Ignore environment lock and execute anyway.
    # 
    def disable(job, host, options = {})
      job.report_running("Discovering host's registered node name")
      node_name = registered_as(host)
      if !node_name
        # TODO auth could fail and cause this to throw
        job.report_failure("Could not discover the host's node name. The host may not be " +
                           "registered with Chef or the embedded Ruby used to identify the " +
                           "node name may not be available. #{host} was not disabled!")
      end
      job.set_status("Host registered as #{node_name}.")

      node = fetch_node(job, node_name)

      required_run_list = []
      success = false
      chef_synchronize(chef_environment: node.chef_environment, force: options[:force], job: job) do
        if node.run_list.include?(DISABLED_RUN_LIST_ENTRY)
          job.set_status("#{node.name} is already disabled.")
          success = true
        else
          required_run_list = on_dynamic_services(job, node) do |dynamic_service, plugin|
            dynamic_service.node_state_change(job,
                                              plugin,
                                              node,
                                              MB::Gear::DynamicService::STOP,
                                              false)
          end
        end

        if !success
          if !required_run_list.empty?
            job.set_status "Running chef with the following run list: #{required_run_list.inspect}"
            self.bulk_chef_run(job, [node], required_run_list)
          else
            job.set_status "No recipes required to run."
          end

          node.run_list = [DISABLED_RUN_LIST_ENTRY].concat(node.run_list)
          if node.save
            job.set_status "#{node.name} disabled."
            success = true
          else
            job.set_status "#{node.name} did not save! Disabled run_list entry was unable to be added to the node."
          end
        end
      end
      job.report_boolean(success)
    rescue MotherBrain::ResourceLocked => e
      job.report_failure e.message
    ensure
      job.terminate if job && job.alive?
    end

    private

    def finalize_callback
      log.debug { "Node Querier stopping..." }
    end

    # Returns a String representing the best connector
    # type to use when communicating with a given node
    #
    # @param os [String]
    #   the operating system
    #
    # @return [String]
    def connector_for_os(os)
      case os
      when "windows"
        Ridley::HostCommander::DEFAULT_WINDOWS_CONNECTOR
      when "linux"
        Ridley::HostCommander::DEFAULT_LINUX_CONNECTOR
      else
        nil
      end
    end

    # Run a Ruby script on the target host and return the result of STDOUT. Only scripts
    # that are located in the Mother Brain scripts directory can be used and they should
    # be identified just by their filename minus the extension
    #
    # @example
    #   node_querier.ruby_script('node_name', '33.33.33.10') => 'vagrant.localhost'
    #
    # @param [String] name
    #   name of the script to run on the target node
    # @param [String] host
    #   hostname of the target node
    #   the MotherBrain scripts directory
    # @option options [String] :user
    #   a shell user that will login to each node and perform the bootstrap command on (required)
    # @option options [String] :password
    #   the password for the shell user that will perform the bootstrap
    # @option options [Array, String] :keys
    #   an array of keys (or a single key) to authenticate the ssh user with instead of a password
    # @option options [Float] :timeout (10.0)
    #   timeout value for SSH bootstrap
    # @option options [Boolean] :sudo (true)
    #   bootstrap with sudo
    #
    # @raise [RemoteScriptError] if there was an error in execution
    # @raise [RuntimeError] if an unknown response is returned from Ridley
    #
    # @note
    #   Use {#_ruby_script_} if the caller of this function is same actor as the receiver. You will
    #   not be able to rescue from the RemoteScriptError thrown by {#ruby_script} but you will
    #   be able to rescue from {#_ruby_script_}.
    #
    # @return [String]
    def ruby_script(name, host, options = {})
      name    = name.split('.rb')[0]
      lines   = File.readlines(MB.scripts.join("#{name}.rb"))
      command_lines = lines.collect { |line| line.gsub('"', "'").strip.chomp }

      unless host.present?
        abort RemoteCommandError.new("cannot execute a ruby_script without a hostname or ipaddress")
      end

      response = safe_remote(host) { chef_connection.node.ruby_script(host, command_lines, connector: options[:connector]) }
      
      if response.error?
        raise RemoteScriptError.new(response.stderr.chomp)
      end
      response.stdout.chomp
    end

    def on_dynamic_services(job, node)
      [].tap do |required_run_list|
        node.run_list.each do |run_list_entry|
          next if run_list_entry == DISABLED_RUN_LIST_ENTRY
          plugin = plugin_manager.for_run_list_entry(run_list_entry, node.chef_environment, remote: true)
          if plugin.nil?
            job.report_failure("Could not find plugin for #{run_list_entry}. Aborting command.")
          end
          plugin.components.each do |component|
            services = component.gears(MB::Gear::Service)
            services.each do |service|
              if service.dynamic_service?
                if component.group(service.service_group).includes_recipe? run_list_entry
                  dynamic_service = service.to_dynamic_service
                  yield(dynamic_service, plugin)
                  required_run_list << service.service_recipe
                end
              else
                job.report_failure("Service #{component.name}.#{service.name} is not a dynamic service;" +
                                   " MotherBrain cannot set the state of this service automatically." +
                                   " Aborting command.")
              end
            end
          end
        end
      end.flatten.uniq
    end

    def fetch_node(job, node_name)
      node = safe_remote(node_name) { chef_connection.node.find(node_name) }
    rescue RemoteCommandError => e
      job.report_failure("Encountered error retrieving the node object.")
    end
    
    def safe_remote(host = nil)
      yield
    rescue Exception => e
      msg = "Unhandled Exception: [#{e.class}] #{e.message}"
      msg = "[#{host}] #{msg}" if host
      log.warn { msg }
      log.debug { e.backtrace.join("\n") }
      abort RemoteCommandError.new(msg, host)
    end
  end
end
