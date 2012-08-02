Given /^a configuration file does not exist$/ do
  FileUtils.rm_f(mb_config_path)
end

Given /^a configuration file exists$/ do
  generate_config(mb_config_path)
end

Then /^a MotherBrain config file should exist and contain:$/ do |table|
  config = MB::Config.from_file(ENV['MB_CONFIG'])
  table.raw.each do |key, value|
    config[key].should eql(value)
  end
end
