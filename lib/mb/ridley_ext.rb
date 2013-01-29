require 'ridley'

Dir["#{File.dirname(__FILE__)}/ridley_ext/*.rb"].sort.each do |path|
  require "mb/ridley_ext/#{File.basename(path, '.rb')}"
end
