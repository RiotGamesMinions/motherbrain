Dir["#{File.dirname(__FILE__)}/resources/*.rb"].sort.each do |path|
  require "mb/api_client/resources/#{File.basename(path, '.rb')}"
end
