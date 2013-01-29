Then /^a MotherBrain config file should exist and contain:$/ do |table|
  config = MB::Config.from_file(mb_config_path)
  table.raw.each do |key, value|
    config.get_attribute(key).should eql(value)
  end
end
