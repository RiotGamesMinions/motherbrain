module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module PluginDSL; end
end

Dir["#{File.dirname(__FILE__)}/plugin_dsl/*.rb"].sort.each do |path|
  require "mb/plugin_dsl/#{File.basename(path, '.rb')}"
end
