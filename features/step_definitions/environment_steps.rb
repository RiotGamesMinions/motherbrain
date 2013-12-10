Given(/^there is an environment on the chef server named "(.*?)"$/) do |environment_name|
  ridley.environment.find(environment_name) || ridley.environment.create(name: environment_name)
end

Given(/^the environment "(.*?)" is locked$/) do |environment_name|
  step %Q[I run the "environment lock #{environment_name}" command]
end

Given(/^there is a file from input named "(.*?)"$/) do |file|
  expect(File.exists?(file)).to be_true
end

Given(/^there is not an environment on the chef server named "(.*?)"$/) do |environment_name|
  ridley.environment.find(environment_name).nil? || ridley.environment.delete(environment_name)
end

When(/^I destroy the environment "(.*?)"$/) do |environment_name|
  step %Q[I run the "environment destroy #{environment_name}" command interactively]
  step %q[I type "yes"]
end

When(/^I destroy the environment "(.*?)" with flags:$/) do |environment_name, table|
  flags_string = table.raw.flatten.join(' ')
  step %Q[I run the "environment destroy #{environment_name} #{flags_string}" command]
end

When(/^I create an environment from file "(.*?)"$/) do |file|
  real_file = File.join(File.dirname(__FILE__), "..", "..", file)
  step %Q[I run the "environment from #{real_file}" command]
end

When(/^I create an environment named "(.*?)"$/) do |name|
  step %Q[I run the "environment create #{name}" command]
end


Then(/^there should be an environment "(.*?)" on the chef server$/) do |environment_name|
  expect(ridley.environment.find(environment_name)).to_not be_nil
end

Then(/^there should not be an environment "(.*?)" on the chef server$/) do |environment_name|
  expect(ridley.environment.find(environment_name)).to be_nil
end
