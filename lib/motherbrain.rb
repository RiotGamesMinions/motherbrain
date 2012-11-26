require 'chozo'
require 'ridley'
require 'solve'
require 'thor'
require 'thor/group'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'rye'
require 'mb/rye_ext'
require 'fileutils'
require 'pathname'
require 'forwardable'
require 'set'
require 'ostruct'

if jruby?
  require 'json'
else
  require 'yajl'
end

require 'mb/version'
require 'mb/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :ActorUtil, 'mb/actor_util'
  autoload :Application, 'mb/application'
  autoload :Bootstrap, 'mb/bootstrap'
  autoload :ChefMutex, 'mb/chef_mutex'
  autoload :ChefRunner, 'mb/chef_runner'
  autoload :CleanRoomBase, 'mb/clean_room_base'
  autoload :Command, 'mb/command'
  autoload :Component, 'mb/component'
  autoload :ComponentInvoker, 'mb/component_invoker'
  autoload :Config, 'mb/config'
  autoload :ConfigValidator, 'mb/config_validator'
  autoload :Context, 'mb/context'
  autoload :ContextualModel, 'mb/contextual_model'
  autoload :DynamicInvoker, 'mb/dynamic_invoker'
  autoload :ErrorHandler, 'mb/error_handler'
  autoload :Gear, 'mb/gear'
  autoload :Group, 'mb/group'
  autoload :InvokerBase, 'mb/invoker_base'
  autoload :Invoker, 'mb/invoker'
  autoload :JSONManifest, 'mb/json_manifest'
  autoload :Logging, 'mb/logging'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginInvoker, 'mb/plugin_invoker'
  autoload :PluginLoader, 'mb/plugin_loader'
  autoload :Provisioner, 'mb/provisioner'
  autoload :Provisioners, 'mb/provisioners'
  autoload :RealModelBase, 'mb/real_model_base'
  autoload :SafeReturn, 'mb/safe_return'

  class << self
    attr_writer :ui
    
    # @return [Thor::Shell::Color]
    def ui
      @ui ||= Thor::Shell::Color.new
    end

    # @return [Pathname]
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
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

    # Recursively call a nested array of procs and return their results in a nested array
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

Ridley.set_logger(MB.logger)
Celluloid.logger = MB.logger
