require 'celluloid'
require 'varia_model'
require 'buff/extensions'
require 'buff/ruby_engine/kernel_ext'
require 'buff/platform/kernel_ext'
require 'ridley-connectors'
require 'solve'
require 'thor'
require 'thor/group'
require 'fileutils'
require 'pathname'
require 'forwardable'
require 'set'
require 'ostruct'
require 'multi_json'
require 'mb/version'
require 'mb/errors'
require 'mb/core_ext'
require 'mb/ridley_ext'
require 'mb/thor_ext'

module MotherBrain
  autoload :API, 'mb/api'
  autoload :Application, 'mb/application'
  autoload :Berkshelf, 'mb/berkshelf'
  autoload :Bootstrap, 'mb/bootstrap'
  autoload :Chef, 'mb/chef'
  autoload :ChefMutex, 'mb/chef_mutex'
  autoload :CleanRoomBase, 'mb/clean_room_base'
  autoload :Cli, 'mb/cli'
  autoload :CliClient, 'mb/cli_client'
  autoload :CliGateway, 'mb/cli_gateway'
  autoload :Command, 'mb/command'
  autoload :CommandInvoker, 'mb/command_invoker'
  autoload :CommandRunner, 'mb/command_runner'
  autoload :Component, 'mb/component'
  autoload :Config, 'mb/config'
  autoload :ConfigManager, 'mb/config_manager'
  autoload :CookbookMetadata, 'mb/cookbook_metadata'
  autoload :EnvironmentManager, 'mb/environment_manager'
  autoload :ErrorHandler, 'mb/error_handler'
  autoload :FileSystem, 'mb/file_system'
  autoload :Gear, 'mb/gear'
  autoload :Group, 'mb/group'
  autoload :Job, 'mb/job'
  autoload :JobManager, 'mb/job_manager'
  autoload :JobRecord, 'mb/job_record'
  autoload :JobTicket, 'mb/job_ticket'
  autoload :LockManager, 'mb/lock_manager'
  autoload :Logging, 'mb/logging'
  autoload :NodeFilter, 'mb/node_filter'
  autoload :Manifest, 'mb/manifest'
  autoload :Mixin, 'mb/mixin'
  autoload :NodeQuerier, 'mb/node_querier'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginManager, 'mb/plugin_manager'
  autoload :Provisioner, 'mb/provisioner'
  autoload :SrvCtl, 'mb/srv_ctl'
  autoload :Upgrade, 'mb/upgrade'

  class << self
    extend Forwardable

    attr_writer :ui

    def_delegator "MB::Application.instance", :application
    alias_method :app, :application

    # Path to the root directory of the motherbrain application
    #
    # @return [Pathname]
    def app_root
      @app_root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    # Path to the scripts directory
    #
    # @return [Pathname]
    def scripts
      app_root.join('scripts')
    end

    # @return [Logger]
    def logger
      MB::Logging.logger
    end
    alias_method :log, :logger

    # @param [Logger, nil] obj
    #
    # @return [Logger]
    def set_logger(obj)
      MB::Logging.set_logger(obj)
    end

    # Is motherbrain executing in test mode?
    #
    # @return [Boolean]
    def testing?
      ENV['RUBY_ENV'] == 'test'
    end

    # Takes an array of procs or a an array of arrays of procs and calls them returning their evaluated
    # values in an array at the same depth.
    #
    # @example
    #   procs = [
    #     -> { :one },
    #     -> { :two },
    #     [
    #       -> { :nested },
    #       [
    #         -> { :deep_nested }
    #       ]
    #     ]
    #   ]
    #
    #   expand_procs(procs) => [
    #     :one,
    #     :two,
    #     [
    #       :nested,
    #       [
    #         :deep_nested
    #       ]
    #     ]
    #   ]
    #
    # @param [Array<Proc>, Array<Array<Proc>>] procs
    #   an array of nested arrays and procs
    #
    # @return [Array]
    #   an array of nested arrays and their evaluated values
    def expand_procs(procs)
      procs.map! do |l_proc|
        if l_proc.is_a?(Array)
          expand_procs(l_proc)
        else
          l_proc.call
        end
      end
    end

    def require_or_exit(library, message = nil)
      begin
        require library
      rescue LoadError
        message ||=
          "#{library} was not found. Please add it to your Gemfile, " +
          "and then run `bundle install`."
        raise PrerequisiteNotInstalled, message
      end
    end
  end
end

# Alias for {MotherBrain}
MB = MotherBrain
require_relative 'mb/gears'
require_relative 'mb/provisioners'
require_relative 'mb/rest_gateway'

if MB.testing?
  require 'mb/test'
else
  class MB::Test ; end # Make the constant exist
end
