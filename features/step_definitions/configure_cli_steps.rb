Then /^a MotherBrain config file should exist and contain:$/ do |table|
  config = MB::Config.from_file(ENV['MB_CONFIG'])
  table.raw.each do |key, value|
    config[key].should eql(value)
  end
end
