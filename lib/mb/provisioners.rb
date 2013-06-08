Dir["#{File.dirname(__FILE__)}/provisioners/*.rb"].sort.each do |path|
  begin
    require_relative "provisioners/#{File.basename(path, '.rb')}"
  rescue LoadError; end
end
