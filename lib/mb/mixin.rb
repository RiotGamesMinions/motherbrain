Dir["#{File.dirname(__FILE__)}/mixin/*.rb"].sort.each do |path|
  require "mb/mixin/#{File.basename(path, '.rb')}"
end
