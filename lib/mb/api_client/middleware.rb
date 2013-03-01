Dir["#{File.dirname(__FILE__)}/middleware/*.rb"].sort.each do |path|
  require "mb/api_client/middleware/#{File.basename(path, '.rb')}"
end
