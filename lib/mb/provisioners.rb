module MotherBrain
  # @author Jamie Winsor <jamie@vialstudios.com>
  module Provisioners
    class << self
      # @return [Set]
      def all
        @provisioners ||= Set.new
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/provisioners/*.rb"].sort.each do |path|
  require "mb/provisioners/#{File.basename(path, '.rb')}"
end
