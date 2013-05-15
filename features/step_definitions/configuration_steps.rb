Given /^a motherbrain configuration does not exist$/ do
  FileUtils.rm_f(mb_config_path)
end

Given /^a valid motherbrain configuration$/ do
  generate_valid_config(mb_config_path)
end

Given /^an invalid motherbrain configuration$/ do
  generate_invalid_config(mb_config_path)
end

Then /^a motherbrain config file should exist and contain:$/ do |table|
  config = MB::Config.from_file(mb_config_path)
  table.raw.each do |key, value|
    config.get_attribute(key).should eql(value)
  end
end
