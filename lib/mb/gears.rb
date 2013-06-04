Dir["#{File.dirname(__FILE__)}/gears/*.rb"].sort.each do |path|
  basename = File.basename(path, '.rb')
  begin
    require "mb/gears/#{basename}"
  rescue LoadError => error
    MB.log.warn "Error loading #{basename} gear: #{error.message}"
  end
end
