Given(/^there is an environment on the chef server named "(.*?)"$/) do |environment_name|
  ridley.environment.find(environment_name) || ridley.environment.create(name: environment_name)
end

When(/^I destroy the environment "(.*?)"$/) do |environment_name|
  step %Q[I run the "environment destroy #{environment_name}" command interactively]
  step %q[I type "yes"]
end

Then(/^there should not be an environment "(.*?)" on the chef server$/) do |environment_name|
  ridley.environment.find(environment_name).should be_nil
end

Given(/^the environment "(.*?)" is locked$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^there should be an environment "(.*?)" on the chef server$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^the output should contain:$/) do |string|
  pending # express the regexp above with the code you wish you had
end

When(/^I destroy the environment "(.*?)" with flags:$/) do |arg1, table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end
