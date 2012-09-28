Given /^a plugin "(.*?)" at version "(.*?)"$/ do |name, version|
  config = MB::Config.from_file(ENV['MB_CONFIG'])
  generate_plugin(name, version, config.plugin_paths.first)
end

Given /^I have no plugins$/ do
  config = MB::Config.from_file(ENV['MB_CONFIG'])

  config.plugin_paths.each do |path|
    FileUtils.rm_r(path, force: true)
  end
end
