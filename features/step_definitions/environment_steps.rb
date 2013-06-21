Given(/^there is an environment on the chef server named "(.*?)"$/) do |environment_name|
  ridley.environment.find(environment_name) || ridley.environment.create(name: environment_name)
end

Given(/^the environment "(.*?)" is locked$/) do |environment_name|
  step %Q[I run the "environment lock #{environment_name}" command]
end

When(/^I destroy the environment "(.*?)"$/) do |environment_name|
  step %Q[I run the "environment destroy #{environment_name}" command interactively]
  step %q[I type "yes"]
end

When(/^I destroy the environment "(.*?)" with flags:$/) do |environment_name, table|
  flags_string = table.raw.flatten.join(' ')
  step %Q[I run the "environment destroy #{environment_name} #{flags_string}" command]
end

Then(/^there should be an environment "(.*?)" on the chef server$/) do |environment_name|
  expect(ridley.environment.find(environment_name)).to_not be_nil
end

Then(/^there should not be an environment "(.*?)" on the chef server$/) do |environment_name|
  expect(ridley.environment.find(environment_name)).to be_nil
end
