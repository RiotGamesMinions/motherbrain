module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Mixin; end
end

Dir["#{File.dirname(__FILE__)}/mixin/*.rb"].sort.each do |path|
  require "mb/mixin/#{File.basename(path, '.rb')}"
end

