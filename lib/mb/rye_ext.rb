Dir["#{File.dirname(__FILE__)}/rye_ext/*.rb"].sort.each do |path|
  require "mb/rye_ext/#{File.basename(path, '.rb')}"
end
