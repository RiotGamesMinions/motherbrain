require 'json'
require 'fileutils'
require 'pathname'
require 'set'
require 'ridley'
require 'solve'
require 'thor'
require 'thor/group'

require 'mb/version'
require 'mb/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :Config, 'mb/config'
  autoload :InvokerBase, 'mb/invoker_base'
  autoload :Invoker, 'mb/invoker'
  autoload :Plugin, 'mb/plugin'
  autoload :PluginInvoker, 'mb/plugin_invoker'
  autoload :PluginLoader, 'mb/plugin_loader'
  autoload :Component, 'mb/component'
  autoload :Command, 'mb/command'
  autoload :Group, 'mb/group'

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
