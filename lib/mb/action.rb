module MotherBrain
  module Action
  end
end

Dir["#{File.dirname(__FILE__)}/actions/*.rb"].sort.each do |path|
  require "mb/actions/#{File.basename(path, '.rb')}"
end
