Dir["#{File.dirname(__FILE__)}/provisioners/*.rb"].sort.each do |path|
  require_relative "provisioners/#{File.basename(path, '.rb')}"
end
