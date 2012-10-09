require 'json'
require 'fileutils'
require 'pathname'
require 'forwardable'
require 'set'
require 'ostruct'
require 'ridley'
require 'solve'
require 'thor'
require 'thor/group'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'chozo/core_ext'
require 'rye'
require 'mb/rye_ext'

require 'mb/version'
require 'mb/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :Command, 'mb/command'
  autoload :CommandRunner, 'mb/command_runner'
  autoload :Component, 'mb/component'
  autoload :ComponentInvoker, 'mb/component_invoker'
  autoload :Config, 'mb/config'
  autoload :Context, 'mb/context'
  autoload :DynamicGears, 'mb/dynamic_gears'
  autoload :DynamicInvoker, 'mb/dynamic_invoker'
  autoload :Gear, 'mb/gear'
  autoload :Group, 'mb/group'
  autoload :InvokerBase, 'mb/invoker_base'
  autoload :Invoker, 'mb/invoker'
  autoload :Mixin, 'mb/mixin'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginDSL, 'mb/plugin_dsl'
  autoload :PluginInvoker, 'mb/plugin_invoker'
  autoload :PluginLoader, 'mb/plugin_loader'
  autoload :ProxyObject, 'mb/proxy_object'
  autoload :RealObject, 'mb/real_object'
  autoload :ChefRunner, 'mb/chef_runner'

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
  end
end

unless defined?(MB)
  # Alias for {MotherBrain}
  MB = MotherBrain
end
