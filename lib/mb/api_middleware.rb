module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module ApiMiddleware; end
end

Dir["#{File.dirname(__FILE__)}/api_middleware/*.rb"].sort.each do |path|
  require "mb/api_middleware/#{File.basename(path, '.rb')}"
end
