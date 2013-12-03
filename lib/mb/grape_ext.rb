Dir["#{File.dirname(__FILE__)}/grape_ext/*.rb"].sort.each do |path|
  require "mb/grape_ext/#{File.basename(path, '.rb')}"
end
