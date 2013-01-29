Given /^a plugin "(.*?)" at version "(.*?)"$/ do |name, version|
  config = MB::Config.from_file(ENV['MB_CONFIG'])
  generate_cookbook(name, config.berkshelf.path, version: version)
end

Given /^I have no plugins$/ do
  config = MB::Config.from_file(ENV['MB_CONFIG'])
  FileUtils.rm_r(config.berkshelf.path, force: true)
end
