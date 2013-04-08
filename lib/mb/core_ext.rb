Dir["#{File.dirname(__FILE__)}/core_ext/*.rb"].sort.each do |path|
  require "mb/core_ext/#{File.basename(path, '.rb')}"
end
