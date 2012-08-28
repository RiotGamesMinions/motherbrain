require 'json'
require 'pathname'
require 'ridley'

require 'mb/version'
require 'mb/errors'
require 'mb/config'

# @author Jamie Winsor <jamie@vialstudios.com>
module MotherBrain
  autoload :CliBase, 'mb/cli_base'
  autoload :Cli, 'mb/cli'

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

# JW TODO: dynamically load plugins somehow
require 'mb-pvpnet'
