Given /^a cookbook "(.*?)" at version "(.*?)"$/ do |name, version|
  generate_cookbook(name, version: version, with_plugin: false)
end

Given /^a cookbook "(.*?)" at version "(.*?)" with a plugin$/ do |name, version|
  generate_cookbook(name, version: version, with_plugin: true)
end

Given(/^a cookbook on the Chef Server "(.*?)" at version "(.*?)" with a plugin$/) do |name, version|
  chef_cookbook(name, version, with_plugin: true)
end

Given /^I have an empty Berkshelf$/ do
  FileUtils.rm_r(berkshelf_path, force: true)
end
