require 'json'
require 'fileutils'
require 'pathname'
require 'set'
require 'ridley'
require 'solve'
require 'thor'
require 'thor/group'
require 'active_support/core_ext/hash'

require 'mb/version'
require 'mb/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :Mixin, 'mb/mixin'
  autoload :Config, 'mb/config'
  autoload :InvokerBase, 'mb/invoker_base'
  autoload :Invoker, 'mb/invoker'
  autoload :DynamicInvoker, 'mb/dynamic_invoker'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginDSL, 'mb/plugin_dsl'
  autoload :PluginInvoker, 'mb/plugin_invoker'
  autoload :PluginLoader, 'mb/plugin_loader'
  autoload :Component, 'mb/component'
  autoload :ComponentInvoker, 'mb/component_invoker'
  autoload :Command, 'mb/command'
  autoload :Group, 'mb/group'
  autoload :ProxyObject, 'mb/proxy_object'
  autoload :Gear, 'mb/gear'

  class << self
    def ui
      @ui ||= Thor::Shell::Color.new
    end

    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end
  end
end

unless defined?(MB)
  # Alias for {MotherBrain}
  MB = MotherBrain
end
