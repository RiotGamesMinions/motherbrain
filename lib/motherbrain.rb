require 'celluloid'
require 'chozo'
require 'ridley'
require 'solve'
require 'thor'
require 'thor/group'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'fileutils'
require 'pathname'
require 'forwardable'
require 'set'
require 'ostruct'
require 'multi_json'

require 'mb/version'
require 'mb/errors'
require 'mb/ridley_ext'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :AbstractGear, 'mb/abstract_gear'
  autoload :Api, 'mb/api'
  autoload :ApiClient, 'mb/api_client'
  autoload :ApiHelpers, 'mb/api_helpers'
  autoload :ApiValidators, 'mb/api_validators'
  autoload :Application, 'mb/application'
  autoload :Berkshelf, 'mb/berkshelf'
  autoload :Bootstrap, 'mb/bootstrap'
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
  autoload :Manifest, 'mb/manifest'
  autoload :Mixin, 'mb/mixin'
  autoload :NodeQuerier, 'mb/node_querier'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginManager, 'mb/plugin_manager'
  autoload :Provisioner, 'mb/provisioner'
  autoload :Provisioners, 'mb/provisioners'
  autoload :RestGateway, 'mb/rest_gateway'
  autoload :SrvCtl, 'mb/srv_ctl'
  autoload :Upgrade, 'mb/upgrade'

  CHEF_VERSION = "11.4.0".freeze

  class << self
    extend Forwardable

    attr_writer :ui

    def_delegator "MB::Application.instance", :application
    alias_method :app, :application

    # @return [Thor::Shell::Color]
    def ui
      @ui ||= Thor::Shell::Color.new
    end

    # Path to the root directory of the MotherBrain application
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

    # Is MotherBrain executing in test mode?
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
  end
end

# Alias for {MotherBrain}
MB = MotherBrain
